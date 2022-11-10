# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Generate a unique random string for resource name assignment and key pair
resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

# Map default tags with values to be assigned to all tagged resources
locals {
  global_tags = {
  Owner       = var.owner_tag
  ManagedBy   = "terraform"
  Vendor      = "Zscaler"
  "zs-edge-connector-cluster/${var.name_prefix}-cluster-${random_string.suffix.result}" = "shared"
  }
}

############################################################################################################################
#### The following lines generates a new SSH key pair and stores the PEM file locally. The public key output is used    ####
#### as the instance_key passed variable to the ec2 modules for admin_ssh_key public_key authentication                 ####
#### This is not recommended for production deployments. Please consider modifying to pass your own custom              ####
#### public key file located in a secure location                                                                       ####
############################################################################################################################
# private key for login
resource "tls_private_key" "key" {
  algorithm   = var.tls_key_algorithm
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.name_prefix}-key-${random_string.suffix.result}"
  public_key = tls_private_key.key.public_key_openssh

  provisioner "local-exec" {
    command = <<EOF
      echo "${tls_private_key.key.private_key_pem}" > ${var.name_prefix}-key-${random_string.suffix.result}.pem
      chmod 0600 ${var.name_prefix}-key-${random_string.suffix.result}.pem
EOF
  }
}

## Create the user_data file
locals {
  userdata = <<USERDATA
[ZSCALER]
CC_URL=${var.cc_vm_prov_url}
SECRET_NAME=${var.secret_name}
HTTP_PROBE_PORT=${var.http_probe_port}
USERDATA
}

resource "local_file" "user-data-file" {
  content  = local.userdata
  filename = "user_data"
}


# 1. Network Creation
# Or reference an existing VPC
data "aws_vpc" "selected" {
  id = var.byo_vpc == false ? aws_vpc.vpc1.*.id[0] : var.byo_vpc_id
}

# Or reference an existing Internet Gateway
data "aws_internet_gateway" "selected" {
  internet_gateway_id = var.byo_igw == false ? aws_internet_gateway.igw1.*.id[0] : var.byo_igw_id
}

# Or reference existing NAT Gateways
data "aws_nat_gateway" "selected" {
  count = var.byo_ngw == false ? length(aws_nat_gateway.ngw.*.id) : length(var.byo_ngw_ids)
  id = var.byo_ngw == false ? aws_nat_gateway.ngw.*.id[count.index] : element(var.byo_ngw_ids, count.index)
}

# 2. Create CC network, routing, and appliance
# Or reference existing subnets
data "aws_subnet" "cc-selected" {
count = var.byo_subnets == false ? var.az_count : length(var.byo_subnet_ids)
id = var.byo_subnets == false ? aws_subnet.cc-subnet.*.id[count.index] : element(var.byo_subnet_ids, count.index)
}

# Create X CC VMs per cc_count which will span equally across designated availability zones per az_count
# E.g. cc_count set to 4 and az_count set to 2 or byo_subnet_ids configured for 2 will create 2x CCs in AZ subnet 1 and 2x CCs in AZ subnet 2
module "cc-vm" {
  source              = "/modules/terraform-zscc-aws"
  cc_count            = var.cc_count
  name_prefix         = var.name_prefix
  resource_tag        = random_string.suffix.result
  global_tags         = local.global_tags
  vpc                 = data.aws_vpc.selected.id
  mgmt_subnet_id      = data.aws_subnet.cc-selected.*.id
  service_subnet_id   = data.aws_subnet.cc-selected.*.id
  instance_key        = aws_key_pair.deployer.key_name
  user_data           = local.userdata
  ccvm_instance_type  = var.ccvm_instance_type
  cc_instance_size    = var.cc_instance_size
  cc_callhome_enabled = var.cc_callhome_enabled
}