variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the Workload module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the Workload module resources"
  default     = null
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "Cloud Connector VPC ID"
}

variable "subnet_id" {
  type        = list(string)
  description = "List of private subnet IDs where workload servers will be deployed"
}

variable "appconnector_type" {
  type        = string
  description = "The workload server EC2 instance type"
  default     = "t3.small"
}

variable "instance_key" {
  type        = string
  description = "SSH Key for instances"
}

variable "appconnector_count" {
  type        = number
  description = "number of app connectors to deploy"
  default     = 2
}

variable "appconnector_ami" {
  type        = string
  description = "app connector provisioning key"
}

variable "appconnector_provurl" {
  type        = string
  description = "app connector provisioning key"
}