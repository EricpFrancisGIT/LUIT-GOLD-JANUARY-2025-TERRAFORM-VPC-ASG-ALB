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

