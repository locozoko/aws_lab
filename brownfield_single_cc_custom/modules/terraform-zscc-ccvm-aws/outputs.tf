output "private_ip" {
  description = "Instance Private IP"
  value       = aws_instance.cc_vm.*.private_ip
}

output "availability_zone" {
  description = "Instance Availability Zone"
  value       = aws_instance.cc_vm.*.availability_zone
}

output "id" {
  description = "Instance ID"
  value       = aws_instance.cc_vm.*.id
}