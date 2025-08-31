output "lb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.external-elb.dns_name
}

output "ec2_instance_ids" {
  description = "The IDs of the EC2 instances"
  value       = [aws_instance.samhainwebserver1.id, aws_instance.samhainwebserver2.id]
}

output "ec2_ip_addresses" {
  description = "The IP addresses of the EC2 instances"
  value       = [aws_instance.samhainwebserver1.public_ip, aws_instance.samhainwebserver2.public_ip]
}

output "lb_ip_address" {
  description = "The IP address of the load balancer"
  value       = aws_lb.external-elb.dns_name
}

output "aws_vpc" {
  description = "The ID of the VPC"
  value       = aws_vpc.season-of-samhain.id
}

output "aws_subnet" {
  description = "The ID of the subnet"
  value       = aws_subnet.season-of-samhain.id
}

output "aws_security_group" {
  description = "The ID of the EC2 security group"
  value       = aws_security_group.samhain-sg.id
}

output "aws_lb_security_group" {
  description = "The ID of the Load Balancer security group"
  value       = aws_security_group.samhain-webserver-sg.id
}

output "grafana_security_group" {
  description = "The ID of the Grafana security group"
  value       = aws_security_group.grafana-sg.id
}

output "grafana_arn"{
  description = "The ARN of the Grafana instance"
  value       = aws_grafana_workspace.example.arn
}