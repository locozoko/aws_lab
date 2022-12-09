################################################################################
# Pull in VPC info
################################################################################
data "aws_vpc" "selected" {
  id = var.vpc_id
}

################################################################################
# Create Security Group and Rules
################################################################################
resource "aws_security_group" "appconn_sg" {
  name        = "${var.name_prefix}-appconn-sg-${var.resource_tag}"
  description = "Security group for all App Connectors"
  vpc_id      = data.aws_vpc.selected.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-appconn-sg-${var.resource_tag}" }
  )
}

resource "aws_security_group_rule" "server_appconn_ingress_self" {
  description              = "Allow all inbound to App Connectorr"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.node_sg.id
  cidr_blocks              = ["0.0.0.0/0"]
  to_port                  = 65535
  type                     = "ingress"
}


################################################################################
# Create workload EC2 instances
################################################################################
resource "aws_instance" "appconnector" {
  count                   = var.appconnector_count
  ami                     = var.appconn_ami
  instance_type           = var.appconn_type
  vpc_security_group_ids  = [aws_security_group.appconn-sg.id]
  subnet_id               = element(var.subnet_id, count.index)
  key_name                = var.instance_key
  mykey                   = var.appconn_provkey
  user_data = <<EOF
#!/bin/bash
#Stop the App Connector service which was auto-started at boot time
systemctl stop zpa-connector
#Copy App Connector provisioning key from the ZPA Admin Portal to file
#Make sure that the provisioning key is between double quotes
echo "${var.mykey}" > /opt/zscaler/var/provision_key
#Run a yum update to apply the latest patches
yum update -y
#Start the App Connector service to enroll it in the ZPA cloud
systemctl start zpa-connector
#Wait for the App Connector to download latest build
sleep 60
#Stop and then start the App Connector for the latest build
systemctl stop zpa-connector
systemctl start zpa-connector
EOF
}
  
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-server-appconn${count.index + 1}-${var.resource_tag}" }
  )
