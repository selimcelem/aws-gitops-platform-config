# VPC module

Creates the network foundation for the platform: a VPC with public and private subnets across multiple availability zones, an Internet Gateway, and NAT Gateways for private subnet egress.

## Layout

- VPC with CIDR `10.0.0.0/16` by default.
- 3 public subnets and 3 private subnets, one of each per availability zone.
- Internet Gateway attached to the VPC.
- NAT Gateway in the first public subnet (default: single NAT for cost). Set `single_nat_gateway = false` for one NAT per AZ in production.
- Public route table routing `0.0.0.0/0` to the Internet Gateway.
- Private route tables routing `0.0.0.0/0` to the NAT.

## EKS-aware tagging

Public subnets are tagged with `kubernetes.io/role/elb = 1` and private subnets with `kubernetes.io/role/internal-elb = 1`. This lets the AWS Load Balancer Controller automatically pick the right subnets for internet-facing and internal load balancers.

## Inputs

See `variables.tf`. Key inputs:

- `project_name`, `environment`: combined to form a name prefix used in tags and resource names.
- `aws_region`: the region the VPC lives in.
- `vpc_cidr`: defaults to `10.0.0.0/16`.
- `az_count`: 2 or 3, defaults to 3.
- `single_nat_gateway`: defaults to true (one NAT for the whole VPC). Set to false for one-per-AZ HA.

## Outputs

See `outputs.tf`. The most important outputs for downstream modules:

- `vpc_id`
- `private_subnet_ids` (where EKS nodes, RDS, and pods live)
- `public_subnet_ids` (where ALBs live)
- `availability_zones` (the actual AZ names used)
