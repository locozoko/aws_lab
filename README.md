# AWS US East Lab Deployment

This deploys my lab via terraform cloud in AWS us-east-1 Region.

## How to deploy:

### Deploys the following:
From the examples directory, run the zsec bash script that walks to all required inputs.
- New VPC
- Public and Private Subnets in single AZ
- Bastion Host (linux)
- Workloads (linux)
- Cloud Connectors
- Auto Scale Group
- Gateway Load Balancer
- Route53 Outbound Resolvers for ZPA


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.7.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.1.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.3.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 3.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.7.0 |
| <a name="provider_local"></a> [local](#provider\_local) | ~> 2.2.0 |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.1.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.3.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | ~> 3.4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion"></a> [bastion](#module\_bastion) | ../../modules/terraform-zscc-bastion-aws | n/a |
| <a name="module_cc_asg"></a> [cc\_asg](#module\_cc\_asg) | ../../modules/terraform-zscc-asg-aws | n/a |
| <a name="module_cc_iam"></a> [cc\_iam](#module\_cc\_iam) | ../../modules/terraform-zscc-iam-aws | n/a |
| <a name="module_cc_sg"></a> [cc\_sg](#module\_cc\_sg) | ../../modules/terraform-zscc-sg-aws | n/a |
| <a name="module_gwlb"></a> [gwlb](#module\_gwlb) | ../../modules/terraform-zscc-gwlb-aws | n/a |
| <a name="module_gwlb_endpoint"></a> [gwlb\_endpoint](#module\_gwlb\_endpoint) | ../../modules/terraform-zscc-gwlbendpoint-aws | n/a |
| <a name="module_network"></a> [network](#module\_network) | ../../modules/terraform-zscc-network-aws | n/a |
| <a name="module_route53"></a> [route53](#module\_route53) | ../../modules/terraform-zscc-route53-aws | n/a |
| <a name="module_workload"></a> [workload](#module\_workload) | ../../modules/terraform-zscc-workload-aws | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_key_pair.deployer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [local_file.testbed](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.user_data_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.cc_error_checker](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_testbedconfig"></a> [testbedconfig](#output\_testbedconfig) | AWS Testbed results |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
