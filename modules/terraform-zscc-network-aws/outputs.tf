output "vpc_id" {
  description = "VPC ID"
  value       = data.aws_vpc.vpc_selected.id
}

output "cc_subnet_ids" {
  description = "Cloud Connector Subnet ID"
  value       = data.aws_subnet.cc_subnet_selected.*.id
}

output "workload_subnet_ids" {
  description = "Workloads Subnet ID"
  value       = aws_subnet.workload_subnet.*.id
}

output "route53_subnet_ids" {
  description = "Route 53 Subnet ID"
  value       = aws_subnet.route53_subnet.*.id
}