AWS VPC + ALB + Auto Scaling (Private Subnets) with Terraform

Provision a custom VPC with 2 public & 2 private subnets, proper routing (IGW + NAT), an Application Load Balancer in public subnets, and an Auto Scaling Group of web servers in private subnets—then output the ALB’s public DNS so you can verify the app over the internet.

🚀 What You’ll Deploy

VPC (e.g., 10.0.0.0/16)

2 Public Subnets (for ALB + NAT Gateway)

2 Private Subnets (for ASG instances)

Internet Gateway (egress from public)

1 NAT Gateway in a public subnet (egress for private)

Route Tables (public & private) with associations

Security Groups (ALB SG, EC2/ASG SG)

ALB (HTTP 80) across public subnets

Target Group (HTTP 80) + health checks

Launch Template (Amazon Linux 2/Ubuntu + user data)

Auto Scaling Group across private subnets

Terraform Outputs including alb_dns_name

Design principle: Public entry terminates at the ALB; compute stays private. Outbound internet for instances flows through NAT.

🗺️ Architecture
flowchart LR
  Internet((Internet)) -->|HTTP 80| ALB[Application Load Balancer<br/>Public Subnets]
  ALB -->|Target Group 80| EC2A[EC2 in Private AZ-a]
  ALB -->|Target Group 80| EC2B[EC2 in Private AZ-b]
  EC2A -- Egress --> NAT[NAT Gateway<br/>Public Subnet]
  EC2B -- Egress --> NAT
  NAT --> IGW[Internet Gateway]
  subgraph VPC 10.0.0.0/16
    subgraph Public Subnets
      ALB
      NAT
      IGW
    end
    subgraph Private Subnets
      EC2A
      EC2B
    end
  end
Routing summary

Public RT: 0.0.0.0/0 -> IGW

Private RT: 0.0.0.0/0 -> NAT GW

💰 Cost Notes

NAT Gateway incurs hourly + data processing charges. To save cost, this reference uses one NAT in a single AZ. For production HA, deploy 1 NAT per AZ.

ALB also incurs hourly + LCU usage.

✅ Prerequisites

Terraform >= 1.5 (tested with 1.8+)

AWS CLI configured (aws configure)

An AWS account with permissions to create VPC, EC2, ALB, IAM

SSH keypair (optional, if you want SSH into instances via SSM Session Manager is recommended)

📁 Repository Structure
.
├─ main.tf               # Root orchestrator (or use modules)
├─ variables.tf          # Input variables
├─ outputs.tf            # ALB DNS, etc.
├─ vpc/                  # VPC, subnets, IGW, NAT, routes
├─ alb/                  # ALB, TG, listeners, SG
├─ asg/                  # LT/ASG, SG, user_data
├─ scripts/
│  └─ userdata.sh        # Web bootstrap (nginx/httpd)
└─ README.md

You can keep it monolithic for a simple project or split into modules as above.

🔧 Key Terraform Components (at a glance)

Names below are examples—match to your actual resources.

VPC & Subnets

aws_vpc.main

aws_subnet.public_a, aws_subnet.public_b

aws_subnet.private_a, aws_subnet.private_b

IGW / NAT / EIPs / Routes

aws_internet_gateway.igw

aws_eip.nat_eip (use domain = "vpc")

aws_nat_gateway.nat

aws_route_table.public, aws_route_table.private

aws_route_table_association.*

Security Groups

aws_security_group.alb_sg (ingress 80 from 0.0.0.0/0)

aws_security_group.ec2_sg (ingress 80 from ALB SG)

ALB & Target Group

aws_lb.app

aws_lb_target_group.app_tg (protocol HTTP, port 80, health check path /)

aws_lb_listener.http

Launch Template & Auto Scaling

aws_launch_template.web_lt (user_data installs web server)

aws_autoscaling_group.web_asg (private subnets)

🔑 Variables (example)

Define in variables.tf:

Variable	Type	Default	Description
project_name	string	"vpc-alb-asg"	Name prefix for resources
region	string	"us-east-1"	AWS region
vpc_cidr	string	"10.0.0.0/16"	VPC CIDR
public_subnets	list(string)	["10.0.1.0/24","10.0.2.0/24"]	Public
private_subnets	list(string)	["10.0.11.0/24","10.0.12.0/24"]	Private
instance_type	string	"t3.micro"	ASG instance type
desired_capacity	number	2	ASG desired
min_size	number	2	ASG min
max_size	number	4	ASG max
health_check_path	string	"/"	TG health check path

🧩 Outputs (example)

In outputs.tf:
output "alb_dns_name" {
  description = "Public DNS name of the ALB"
  value       = aws_lb.app.dns_name
}

output "alb_http_url" {
  description = "Convenience HTTP URL"
  value       = "http://${aws_lb.app.dns_name}"
}
💻 User Data (sample)

scripts/userdata.sh (nginx example):
#!/bin/bash
set -euxo pipefail
yum update -y || apt-get update -y || true

# Amazon Linux 2 (yum) path
if command -v yum >/dev/null 2>&1; then
  amazon-linux-extras install -y nginx1
  systemctl enable nginx
  echo "<h1>Welcome from $(hostname -f)</h1>" > /usr/share/nginx/html/index.html
  systemctl start nginx
  exit 0
fi

# Ubuntu (apt) path
if command -v apt-get >/dev/null 2>&1; then
  apt-get install -y nginx
  systemctl enable nginx
  echo "<h1>Welcome from $(hostname -f)</h1>" > /var/www/html/index.nginx-debian.html
  systemctl restart nginx
  exit 0
fi
Make sure your Launch Template points to this file as base64-encoded user_data.

🔐 Security Groups (reference)

ALB SG

Ingress: TCP 80 from 0.0.0.0/0

Egress: All to 0.0.0.0/0

EC2 SG

Ingress: TCP 80 from ALB SG (security group reference, not CIDR)

Egress: All to 0.0.0.0/0 (for yum/apt via NAT)

▶️ How to Deploy

# 1) Initialize
terraform init

# 2) Preview
terraform plan -out tfplan

# 3) Apply
terraform apply tfplan

Tip: Pass variables via terraform.tfvars or -var="key=value".

🔎 Verify the Deployment

1. Get outputs

terraform output
# or
terraform output alb_http_url

2. Open ALB URL in a browser or:
curl -I $(terraform output -raw alb_http_url)
# Expect HTTP/1.1 200 OK

3. ALB Target Group health should be healthy for both instances.

4. Scaling test (optional): Generate load or change ASG capacity:
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name <your-asg-name> --desired-capacity 3

🧹 Teardown

terraform destroy

If destroy fails due to dependencies, delete the ALB and NAT Gateway last (Terraform handles order, but dangling resources or manual edits can complicate it). Ensure S3 backends aren’t locked.

🧰 Troubleshooting

NAT EIP error

Use aws_eip with domain = "vpc" (do not use vpc = true, it’s deprecated).

“Incorrect attribute value type” (VPC ID)

Use the .id attribute:
vpc_id = aws_vpc.main.id

ASG: “Instance type does not exist in the launch template”

Ensure your Launch Template sets instance_type.

If using AMI that requires specific virtualization, pick a valid AMI for the region.

ALB Target Group attachment failures

Don’t attach instances directly when using ASG; the ASG should register instances with the Target Group via target_group_arns.

Health checks failing

Confirm user data actually starts nginx/httpd.

Health check path (/) matches installed web root and returns 200.

Routes not working

Public RT must point 0.0.0.0/0 to IGW.

Private RT must point 0.0.0.0/0 to NAT Gateway.

Ensure route table associations per subnet.

🧪 Notes for Production Hardening

Use NAT per AZ for HA.

Add HTTPS (443) on ALB + ACM certificate + redirect 80→443.

Use SSM Agent & Session Manager (no SSH).

Tighten SGs/CIDRs and add WAF if needed.

Add Auto Scaling policies (CPU target tracking).

Centralize logs: ALB access logs (S3), instance logs (CloudWatch).

Use private ALB + public CloudFront for additional patterns.

📜 Example Provider (snippet)

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

✅ Deliverables Checklist
Custom VPC with 2 public + 2 private subnets
IGW + NAT Gateway + proper routing
ALB in public subnets
ASG in private subnets (reachable only via ALB)
alb_dns_name output
Screenshot/recording verifying the web page at ALB URL

📎 License

MIT (or your org’s standard)