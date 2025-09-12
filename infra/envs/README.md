This folder is a root module that composes the reusable network module in ../../modules.

Usage:
- Copy one of the tfvars under dev/staging/prod and adjust values.
- Optional: set AZs and custom subnet CIDRs. If omitted, they are derived from vpc_cidr.
- Toggle feature flags like enable_nat_gateway, enable_flow_logs, enable_nacls.

Outputs provide VPC and subnet IDs to attach compute resources later.
