# aws variables

variable "tls_key_algorithm" {
  default   = "RSA"
  type      = string
}

locals {
  small_cc_instance  = ["t3.medium","m5.large","c5.large","c5a.large","m5.2xlarge","c5.2xlarge","m5.4xlarge","c5.4xlarge"]
  medium_cc_instance = ["m5.2xlarge","c5.2xlarge","m5.4xlarge","c5.4xlarge"]
  large_cc_instance  = ["m5.4xlarge","c5.4xlarge"]
  
  valid_cc_create = (
contains(local.small_cc_instance, var.ccvm_instance_type) && var.cc_instance_size == "small"   ||
contains(local.medium_cc_instance, var.ccvm_instance_type) && var.cc_instance_size == "medium" ||
contains(local.large_cc_instance, var.ccvm_instance_type) && var.cc_instance_size == "large"
 )
}
