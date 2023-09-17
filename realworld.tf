provider "aws" {
  region     = "us-west-2"
  access_key = "YOUR_AWS_ACCESS_KEY"
  secret_key = "YOUR_AWS_SECRET_KEY"
}

# VPC Setup
resource "aws_vpc" "realworld_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "realworld_vpc"
  }
}

resource "aws_subnet" "realworld_subnet_a" {
  vpc_id           = aws_vpc.realworld_vpc.id
  cidr_block       = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true  
  tags = {
    Name = "realworld_subnet_a"
  }
}

resource "aws_subnet" "realworld_subnet_b" {
  vpc_id           = aws_vpc.realworld_vpc.id
  cidr_block       = "10.0.2.0/24"
  availability_zone = "us-west-2b"
  map_public_ip_on_launch = true  
  tags = {
    Name = "realworld_subnet_b"
  }
}

resource "aws_internet_gateway" "realworld_igw" {
  vpc_id = aws_vpc.realworld_vpc.id
}

resource "aws_route_table" "realworld_route_table" {
  vpc_id = aws_vpc.realworld_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.realworld_igw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.realworld_subnet_a.id
  route_table_id = aws_route_table.realworld_route_table.id
}

# Security Group Setup
resource "aws_security_group" "realworld_app_sg" {
  vpc_id = aws_vpc.realworld_vpc.id
  name        = "realworld_app_sg"
  description = "Allow inbound traffic for RealWorld App"

  ingress {
    from_port   = 22 # SSH
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000 # Backend port
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4100 # Frontend port
    to_port     = 4100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance Setup with User Data
resource "aws_instance" "realworld_app" {
  ami           = "ami-03f65b8614a860c29"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.realworld_subnet_a.id
  availability_zone = "us-west-2a"
  vpc_security_group_ids = [aws_security_group.realworld_app_sg.id]
  key_name      = "Ansible3"

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update && sudo apt upgrade -y

              # Installing NodeJS
              curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
              sudo apt-get install -y nodejs git

              # Installing MongoDB
              sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
              echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list
              sudo apt-get update
              sudo apt-get install -y mongodb-org
              sudo systemctl start mongod
              sudo systemctl enable mongod

              # Setting up RealWorld backend
              mkdir -p /opt/realworld_backend
              git clone https://github.com/gothinkster/node-express-realworld-example-app.git /opt/realworld_backend
              cd /opt/realworld_backend
              npm install
              nohup npm start > backend.log 2>&1 &

              # Setting up RealWorld frontend
              mkdir -p /opt/realworld_frontend
              git clone https://github.com/gothinkster/react-redux-realworld-example-app.git /opt/realworld_frontend
              cd /opt/realworld_frontend
              npm install
              nohup npm start > frontend.log 2>&1 &
              EOF

  tags = {
    Name = "RealWorldAppInstance"
  }
}

# Load Balancer Setup
resource "aws_lb" "realworld_lb" {
  name               = "realworld-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.realworld_app_sg.id]
  subnets            = [aws_subnet.realworld_subnet_a.id, aws_subnet.realworld_subnet_b.id]
  enable_deletion_protection = false

  enable_cross_zone_load_balancing   = true
  idle_timeout                       = 400
  enable_http2                       = true

  tags = {
    Name = "realworld-lb"
  }
}

resource "aws_lb_listener" "realworld_frontend_listener" {
  load_balancer_arn = aws_lb.realworld_lb.arn
  port              = "4100"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.realworld_frontend_tg.arn
  }
}

resource "aws_lb_listener" "realworld_backend_listener" {
  load_balancer_arn = aws_lb.realworld_lb.arn
  port              = "3000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.realworld_backend_tg.arn
  }
}

resource "aws_lb_target_group" "realworld_frontend_tg" {
  name     = "realworld-frontend-tg"
  port     = 4100
  protocol = "HTTP"
  vpc_id   = aws_vpc.realworld_vpc.id
}

resource "aws_lb_target_group" "realworld_backend_tg" {
  name     = "realworld-backend-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.realworld_vpc.id
}

resource "aws_lb_target_group_attachment" "realworld_frontend_attachment" {
  target_group_arn = aws_lb_target_group.realworld_frontend_tg.arn
  target_id        = aws_instance.realworld_app.id
}

resource "aws_lb_target_group_attachment" "realworld_backend_attachment" {
  target_group_arn = aws_lb_target_group.realworld_backend_tg.arn
  target_id        = aws_instance.realworld_app.id
}


# Route53 Domain Setup
resource "aws_route53_zone" "realworld_domain" {
  name = "yourdomain.com"
  comment = "Hosted zone for RealWorld App"

  tags = {
    Environment = "Production"
  }
}

# Route53 Record Setup
resource "aws_route53_record" "realworld_record" {
  zone_id = aws_route53_zone.realworld_domain.zone_id
  name    = "realworld.yourdomain.com"
  type    = "A"

  alias {
    name                   = aws_lb.realworld_lb.dns_name
    zone_id                = aws_lb.realworld_lb.zone_id
    evaluate_target_health = false
  }
}
