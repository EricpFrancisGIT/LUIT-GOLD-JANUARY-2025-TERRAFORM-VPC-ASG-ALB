#backend for logs/terraform statefile

terraform {
  backend "s3" {
    bucket = "luit-terraform-project2-08242025"
    key    = "luit-terraform-project2-08242025/terraform/state.tf"
    region = "us-east-1"
  }
}


# Create a VPC
resource "aws_vpc" "season-of-samhain" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Season-of-Samhain VPC"
  }
}

# Create Public Subnets
resource "aws_subnet" "Samhain-Public-SN1" {
  vpc_id                  = aws_vpc.season-of-samhain.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Samhain-Public-SN1"
  }
}

resource "aws_subnet" "Samhain-Public-SN2" {
  vpc_id                  = aws_vpc.season-of-samhain.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Samhain-Public-SN2"
  }
}

# Creating Private Subnets
resource "aws_subnet" "Samhain-Private-SN1" {
  vpc_id                  = aws_vpc.season-of-samhain.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "Samhain-Private-SN1"
  }
}

resource "aws_subnet" "Samhain-Private-SN2" {
  vpc_id                  = aws_vpc.season-of-samhain.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1d"
  map_public_ip_on_launch = false

  tags = {
    Name = "Samhain-Private-SN2"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.season-of-samhain.id

  tags = {
    Name = "Samhain-IGW"
  }
}

# Create the route table
resource "aws_route_table" "Samhain-RT" {
  vpc_id = aws_vpc.season-of-samhain.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Samhain-RT"
  }
}

# Create Web Subnet association with Web route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.Samhain-Public-SN1.id
  route_table_id = aws_route_table.Samhain-RT.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.Samhain-Public-SN2.id
  route_table_id = aws_route_table.Samhain-RT.id
}

#Create EC2 Instance
resource "aws_instance" "samhainwebserver1" {
  ami                    = "ami-00ca32bbc84273381"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1a"
  vpc_security_group_ids = [aws_security_group.samhain-webserver-sg.id]
  subnet_id              = aws_subnet.Samhain-Public-SN1.id
  user_data              = file("samhain_apache.sh")

  tags = {
    Name = "Samhain-Webserver1"
  }

}

resource "aws_instance" "samhainwebserver2" {
  ami                    = "ami-00ca32bbc84273381"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1b"
  vpc_security_group_ids = [aws_security_group.samhain-webserver-sg.id]
  subnet_id              = aws_subnet.Samhain-Public-SN2.id
  user_data              = file("samhain_apache.sh")

  tags = {
    Name = "Samhain-Webserver2"
  }

}

# Create Web Security Group
resource "aws_security_group" "samhain-sg" {
  name        = "Samhain-SG"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.season-of-samhain.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH for Management"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Samhain-SG"
  }
}

# Create ALB Security Group
resource "aws_security_group" "samhain-webserver-sg" {
  name        = "Samhain-Webserver-SG"
  description = "Allow inbound traffic from ALB"
  vpc_id      = aws_vpc.season-of-samhain.id

  ingress {
    description     = "Allowing traffic from Loadbalancer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.samhain-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Samhain-Webserver-SG"
  }
}


resource "aws_lb" "external-alb" {
  name               = "External-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.samhain-sg.id]
  subnets            = [aws_subnet.Samhain-Public-SN1.id, aws_subnet.Samhain-Public-SN2.id]
}

resource "aws_lb_target_group" "external-alb" {
  name     = "Samhain-ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.season-of-samhain.id
}

resource "aws_lb_target_group_attachment" "external-alb1" {
  target_group_arn = aws_lb_target_group.external-alb.arn
  target_id        = aws_instance.samhainwebserver1.id
  port             = 80

  depends_on = [
    aws_instance.samhainwebserver1,
  ]
}

resource "aws_lb_target_group_attachment" "external-alb2" {
  target_group_arn = aws_lb_target_group.external-alb.arn
  target_id        = aws_instance.samhainwebserver2.id
  port             = 80

  depends_on = [
    aws_instance.samhainwebserver2,
  ]
}

resource "aws_lb_listener" "external-alb" {
  load_balancer_arn = aws_lb.external-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external-alb.arn
  }
}

####AutoScaling 
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
resource "aws_launch_template" "webASG" {
  name_prefix            = "SpiritsofSamhain-lt"
  image_id               = data.aws_ssm_parameter.al2023.value
  instance_type          = "t2.micro"
  user_data              = filebase64("samhain_apache.sh")
  vpc_security_group_ids = [aws_security_group.samhain-sg.id]
}
resource "aws_autoscaling_group" "app" {
  name                      = "SpiritsofSamhain-asg"
  desired_capacity          = 5
  min_size                  = 2
  max_size                  = 5
  vpc_zone_identifier       = [aws_subnet.Samhain-Public-SN1.id, aws_subnet.Samhain-Public-SN2.id]
  health_check_type         = "ELB"
  health_check_grace_period = 60
  target_group_arns         = [aws_lb_target_group.external-alb.arn]

  launch_template {
    id      = aws_launch_template.webASG.id # <-- use the Terraform resource reference
    version = "$Latest"
  }
}
resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "SpiritsofSamhain-cpu-tt"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.app.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80
  }
}