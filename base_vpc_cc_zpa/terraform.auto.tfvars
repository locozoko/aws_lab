domain_names = {
  appseg1 = "ikovacs.com"
  appseg2 = "ikovacs.lab"
  appseg3 = "mrpicklez.net"
}

cc_vm_prov_url                             = "connector.zscalertwo.net/api/v1/provUrl?name=ZLAB"

secret_name                                =  "ZS/CC/credentials"

http_probe_port                            = 50000

name_prefix                                = "ZLAB"

aws_region                                 = "us-east-1"

ccvm_instance_type                         = "t3.medium"
#ccvm_instance_type                         = "m5.large"
#ccvm_instance_type                         = "c5.large"
#ccvm_instance_type                         = "c5a.large"
#ccvm_instance_type                         = "m5.2xlarge"
#ccvm_instance_type                         = "c5.2xlarge"
#ccvm_instance_type                         = "m5.4xlarge"
#ccvm_instance_type                         = "c5.4xlarge"

cc_instance_size                           = "small"
#cc_instance_size                           = "medium"
#cc_instance_size                           = "large" 

az_count                                   = 1

cc_count                                   = 2

vpc_cidr                                   = "10.0.0.0/16"

#public_subnets                             = ["10.x.y.z/24","10.x.y.z/24"]
#workloads_subnets                          = ["10.x.y.z/24","10.x.y.z/24"]
#cc_subnets                                 = ["10.x.y.z/24","10.x.y.z/24"]
#route53_subnets                            = ["10.x.y.z/24","10.x.y.z/24"]

workload_count                             = 2

owner_tag                                  = "Zoltan"

cc_callhome_enabled                        = true

cross_zone_lb_enabled                      = true

#flow_stickiness                            = "2-tuple"
#flow_stickiness                            = "3-tuple"
flow_stickiness                            = "5-tuple"

rebalance_enabled                          = true

reuse_security_group                       = true

reuse_iam                                  = true

acceptance_required                        = false

#allowed_principals                         = [\"arn:aws:iam::1234567890:root\"]

instance_key                               = "zoltan-zscaler-aws"