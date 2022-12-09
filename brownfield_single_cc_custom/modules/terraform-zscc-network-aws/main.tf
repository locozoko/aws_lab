################################################################################
# Network Infrastructure Resources
################################################################################
# Identify availability zones available for region selected
data "aws_availability_zones" "available" {
  state = "available"
}


################################################################################
# VPC
################################################################################
# Create a new VPC
resource "aws_vpc" "vpc" {
  count                = var.byo_vpc == false ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-vpc-${var.resource_tag}" }
  )
}

# Or reference an existing VPC
data "aws_vpc" "vpc_selected" {
  id = var.byo_vpc == false ? aws_vpc.vpc.*.id[0] : var.byo_vpc_id
}

################################################################################
# Private (Workload) Subnet & Route Tables
################################################################################
# Create equal number of Workload/Private Subnets to how many Cloud Connector subnets exist. This will not be created if var.workloads_enabled is set to False
resource "aws_subnet" "workload_subnet" {
  count             = var.workloads_enabled == true ? length(aws_subnet.cc_subnet.*.id) : 0
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.workloads_subnets != null ? element(var.workloads_subnets, count.index) : cidrsubnet(data.aws_vpc.vpc_selected.cidr_block, 8, count.index + 1)
  vpc_id            = data.aws_vpc.vpc_selected.id

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-workload-subnet-${count.index + 1}-${var.resource_tag}" }
  )
}

# Create Route Table for private subnets (workload servers) towards CC Service ENI or GWLB Endpoint depending on deployment type
resource "aws_route_table" "workload_rt" {
  count  = length(aws_subnet.workload_subnet.*.id)
  vpc_id = data.aws_vpc.vpc_selected.id
  route {
    cidr_block           = "0.0.0.0/0"
    vpc_endpoint_id      = var.gwlb_enabled == true ? element(var.gwlb_endpoint_ids, count.index) : null
    network_interface_id = var.gwlb_enabled == false ? element(var.cc_service_enis, count.index) : null
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-workload-to-cc-${count.index + 1}-rt-${var.resource_tag}" }
  )
}

# Create Workload Route Table Association
resource "aws_route_table_association" "workload_rt_association" {
  count          = length(aws_subnet.workload_subnet.*.id)
  subnet_id      = aws_subnet.workload_subnet.*.id[count.index]
  route_table_id = aws_route_table.workload_rt.*.id[count.index]
}


################################################################################
# Private (Cloud Connector) Subnet & Route Tables
################################################################################
# Create subnet for CC network in X availability zones per az_count variable
resource "aws_subnet" "cc_subnet" {
  count = var.byo_subnets == false ? var.az_count : 0

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.cc_subnets != null ? element(var.cc_subnets, count.index) : cidrsubnet(data.aws_vpc.vpc_selected.cidr_block, 8, count.index + 200)
  vpc_id            = data.aws_vpc.vpc_selected.id

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-subnet-${count.index + 1}-${var.resource_tag}" }
  )
}

# Or reference existing subnets
data "aws_subnet" "cc_subnet_selected" {
  count = var.byo_subnets == false ? var.az_count : length(var.byo_subnet_ids)
  id    = var.byo_subnets == false ? aws_subnet.cc_subnet.*.id[count.index] : element(var.byo_subnet_ids, count.index)
}

################################################################################
# Private (Route 53 Endpoint) Subnet & Route Tables
################################################################################
# Optional Route53 subnet creation for ZPA
# Create Route53 Subnets. Defaults to 2 minimum. Modify the count here if you want to create more than 2.
resource "aws_subnet" "route53_subnet" {
  count             = var.zpa_enabled == true ? 2 : 0
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.route53_subnets != null ? element(var.route53_subnets, count.index) : cidrsubnet(data.aws_vpc.vpc_selected.cidr_block, 12, (64 + count.index * 16))
  vpc_id            = data.aws_vpc.vpc_selected.id

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-route53-subnet-${count.index + 1}-${var.resource_tag}" }
  )
}

# Create Route Table for Route53 routing to GWLB Endpoint in the same AZ for DNS redirection
resource "aws_route_table" "route53_rt" {
  count  = var.zpa_enabled == true ? length(aws_subnet.route53_subnet.*.id) : 0
  vpc_id = data.aws_vpc.vpc_selected.id
  route {
    cidr_block           = "0.0.0.0/0"
    vpc_endpoint_id      = var.gwlb_enabled == true ? element(var.gwlb_endpoint_ids, count.index) : null
    network_interface_id = var.gwlb_enabled == false ? element(var.cc_service_enis, count.index) : null
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-route53-to-cc-${count.index + 1}-rt-${var.resource_tag}" }
  )
}

# Route53 Subnets Route Table Assocation
resource "aws_route_table_association" "route53_rt_asssociation" {
  count          = var.zpa_enabled == true ? length(aws_subnet.route53_subnet.*.id) : 0
  subnet_id      = aws_subnet.route53_subnet.*.id[count.index]
  route_table_id = aws_route_table.route53_rt.*.id[count.index]
}
