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
# Identify availability zones available for region selected
data "aws_availability_zones" "available" {
  state = "available"
}

# Or reference an existing VPC
data "aws_vpc" "selected" {
  id = var.byo_vpc_id
}

# Or reference an existing Internet Gateway
data "aws_internet_gateway" "selected" {
  internet_gateway_id = var.byo_igw_id
}

# Or reference existing NAT Gateways
data "aws_nat_gateway" "selected" {
  id = var.byo_ngw == element(var.byo_ngw_ids, count.index)
}



# 2. Create CC network, routing, and appliance

# Or reference existing subnets
data "aws_subnet" "cc-selected" {
id = var.byo_subnets == element(var.byo_subnet_ids, count.index)
}

# Validation for Cloud Connector instance size and EC2 Instance Type compatibilty. A file will get generated in root path if this error gets triggered.
resource "null_resource" "cc-error-checker" {
  count = local.valid_cc_create ? 0 : 1 # 0 means no error is thrown, else throw error
  provisioner "local-exec" {
    command = <<EOF
      echo "Cloud Connector parameters were invalid. No appliances were created. Please check the documentation and cc_instance_size / ccvm_instance_type values that were chosen" >> errorlog.txt
EOF
  }
}

# Create X CC VMs per cc_count which will span equally across designated availability zones per az_count
# E.g. cc_count set to 4 and az_count set to 2 or byo_subnet_ids configured for 2 will create 2x CCs in AZ subnet 1 and 2x CCs in AZ subnet 2
module "cc-vm" {
  source              = "github.com/locozoko/zscc_tf_lab/modules/terraform-zscc-aws"
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


# 3. Create GWLB in all CC subnets. Create 1x GWLB Endpoint per subnet with Endpoint Service. Create Target Group and attach primary service IP from all created Cloud
#    Connectors as registered targets.
module "gwlb" {
  source                    = "github.com/locozoko/zscc_tf_lab/modules/terraform-zsgwlb-aws"
  name_prefix               = var.name_prefix
  resource_tag              = random_string.suffix.result
  global_tags               = local.global_tags
  vpc                       = data.aws_vpc.selected.id
  cc_subnet_ids             = data.aws_subnet.cc-selected.*.id
  cc_small_service_ips      = module.cc-vm.cc_service_private_ip
  cc_med_lrg_service_1_ips  = module.cc-vm.cc_med_lrg_service_1_private_ip 
  cc_med_lrg_service_2_ips  = module.cc-vm.cc_med_lrg_service_2_private_ip
  cc_lrg_service_3_ips      = module.cc-vm.cc_lrg_service_3_private_ip
  cc_instance_size          = var.cc_instance_size
  http_probe_port           = var.http_probe_port
  cross_zone_lb_enabled     = var.cross_zone_lb_enabled
  interval                  = 10
  healthy_threshold         = 3
  unhealthy_threshold       = 3
}



# 4. Create Endpoint Service associated with GWLB and 1x GWLB Endpoint per CC subnet
module "gwlb-endpoint" {
  source                  = "github.com/locozoko/zscc_tf_lab/modules/terraform-zsgwlbendpoint-aws"
  name_prefix             = var.name_prefix
  resource_tag            = random_string.suffix.result
  global_tags             = local.global_tags
  vpc                     = data.aws_vpc.selected.id
  cc_subnet_ids           = data.aws_subnet.cc-selected.*.id
  gwlb_arn                = module.gwlb.gwlb_arn
}



############################################################################################################################################
####### Legacy code for reference if customer desires to break cloud connector mgmt and service interfaces out into separate subnets #######
############################################################################################################################################

# create new subnet for CC mgmt n/w
#resource "aws_subnet" "cc-mgmt-subnet" {
#  count = 2
#
#  availability_zone = data.aws_availability_zones.available.names[count.index]
#  cidr_block        = cidrsubnet(aws_vpc.vpc1.cidr_block, 12, (count.index * 16) + 3936)
#  vpc_id            = aws_vpc.vpc1.id
#
#  tags = map(
#    "Name", "${var.name_prefix}-vpc1-ec-mgmt-subnet-${count.index + 1}-${random_string.suffix.result}",
#    "zs-edge-connector-cluster/${var.name_prefix}-cluster-${random_string.suffix.result}", "shared",
#  )
#}

#CC Mgmt/Service NATGW Route Table
#resource "aws_route_table" "routetable-cc-mgmt-and-service" {
#  count  = 1
#  vpc_id = aws_vpc.vpc1.id
#  route {
#    cidr_block     = "0.0.0.0/0"
#    nat_gateway_id = aws_nat_gateway.ngw1.id
#  }
#
#  tags = map(
#    "Name", "${var.name_prefix}-natgw-cc-mgmt-svc-rt-${count.index + 1}-${random_string.suffix.result}",
#    "zs-edge-connector-cluster/${var.name_prefix}-cluster-${random_string.suffix.result}", "shared",
#  )
#}

#CC Mgmt subnet NATGW Route Table Association
#resource "aws_route_table_association" "routetable-cc-mgmt" {
#  count          = 2
#  subnet_id      = aws_subnet.cc-mgmt-subnet.*.id[count.index]
#  route_table_id = aws_route_table.routetable-cc-mgmt-and-service.*.id[0]
#}

# create new subnet for CC service n/w
#resource "aws_subnet" "cc-service-subnet" {
#  count             = 2
#  availability_zone = data.aws_availability_zones.available.names[count.index]
#  cidr_block        = cidrsubnet(aws_vpc.vpc1.cidr_block, 12, (count.index * 16) + 4000)
#  vpc_id            = aws_vpc.vpc1.id
#
#  tags = map(
#    "Name", "${var.name_prefix}-ec-service-subnet-${count.index + 1}-${random_string.suffix.result}",
#    "zs-edge-connector-cluster/${var.name_prefix}-cluster-${random_string.suffix.result}", "shared",
#  )
#}

#EC Service subnet NATGW Route Table Association
#resource "aws_route_table_association" "routetable-cc-service" {
#  count          = 2
#  subnet_id      = aws_subnet.cc-service-subnet.*.id[count.index]
#  route_table_id = aws_route_table.routetable-cc-mgmt-and-service.*.id[0]
#}
