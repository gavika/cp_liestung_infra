
  //////// mgmt Env ///////////

    resource "aws_vpc" "mgmt_vpc" {
      cidr_block = "10.2.0.0/16"
      enable_dns_support = true
      enable_dns_hostnames = true

      tags = {
        Name = "mgmt_vpc"
        
        env ="mgmt"
      }
    }

    resource "aws_internet_gateway" "mgmt_ig" {
      vpc_id = aws_vpc.mgmt_vpc.id

      tags = {
        Name = "mgmt_ig"
        
        env ="mgmt"
      }
    }

    resource "aws_subnet" "mgmt_public_subnet_1" {
      vpc_id = aws_vpc.mgmt_vpc.id
      cidr_block              = "10.2.1.0/24"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = true

      tags = {
        Name = "mgmt_Public Subnet_1"
        
        env ="mgmt"
      }
    }

    resource "aws_subnet" "mgmt_public_subnet_2" {
          vpc_id = aws_vpc.mgmt_vpc.id
          cidr_block              = "10.2.2.0/24"
          availability_zone       = "us-east-1b"
          map_public_ip_on_launch = true

          tags = {
            Name = "mgmt_Public Subnet_2"
            
            env ="mgmt"
          }
        }


    resource "aws_subnet" "mgmt_public_subnet_3" {
          vpc_id = aws_vpc.mgmt_vpc.id
          cidr_block              = "10.2.3.0/24"
          availability_zone       = "us-east-1c"
          map_public_ip_on_launch = true
          
          tags = {
            Name = "mgmt_Public Subnet_3"
            
            env ="mgmt"
          }
        }

    resource "aws_subnet" "mgmt_private_subnet_1" {
          vpc_id = aws_vpc.mgmt_vpc.id
          cidr_block              = "10.2.4.0/24"
          availability_zone       = "us-east-1a"
          
          tags = {
            Name = "mgmt_private Subnet_1"
            
            env ="mgmt"
          }
        }
    resource "aws_subnet" "mgmt_private_subnet_2" {
          vpc_id = aws_vpc.mgmt_vpc.id
          cidr_block              = "10.2.5.0/24"
          availability_zone       = "us-east-1b"
       
          tags = {
            Name = "mgmt_private Subnet_1"
            
            env ="mgmt"
          }
        }
    resource "aws_route_table" "mgmt_route_table_public" {
      vpc_id = aws_vpc.mgmt_vpc.id
      route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.mgmt_ig.id
      }
      tags = {
        Name = "mgmt_route_table_public"
        
        env ="mgmt"
      }
    }


resource "aws_db_subnet_group" "mgmt_db_subnet_group" {
  name       = "mgmt-db-subnet-group"
  subnet_ids = [aws_subnet.mgmt_private_subnet_1.id,aws_subnet.mgmt_private_subnet_2.id]
  tags = {
   
    env ="mgmt"
  }
}

resource "aws_elasticache_subnet_group" "mgmt_ec_subnet_group" {
  name       = "mgmt-ec-subnet-group"
  subnet_ids = [aws_subnet.mgmt_private_subnet_1.id,aws_subnet.mgmt_private_subnet_2.id]
  tags = {
   
    env ="mgmt"
  }
}



resource "aws_eip" "mgmt_eip" {
  domain = "vpc"
  tags = {
   
    env ="mgmt"
  }
}
resource "aws_nat_gateway" "mgmt_nat_gateway" {
    subnet_id = aws_subnet.mgmt_public_subnet_1.id
    allocation_id = aws_eip.mgmt_eip.id
    tags = {
        Name= "mgmt_nat_gateway"
   
    env ="mgmt"
  }
  
}

    resource "aws_key_pair" "mgmt_key" {
       key_name = "mgmt_key"
      public_key = tls_private_key.mgmt_rsa_key.public_key_openssh
      tags = {
        Name = "mgmt_key"
        env ="mgmt"
      }
    }

    resource "tls_private_key" "mgmt_rsa_key" {
      algorithm = "RSA"
      rsa_bits  = 4096
    }

    resource "local_file" "mgmt_key" {
    content  = tls_private_key.mgmt_rsa_key.private_key_pem
    filename = "mgmt_key.pem"
    }



   
    resource "aws_instance" "mgmt_ec2_vpn" {
    
    subnet_id = aws_subnet.mgmt_public_subnet_1.id
    instance_type = "t3.medium" 
    ami = "ami-0c7217cdde317cfec"
    key_name = aws_key_pair.mgmt_key.key_name

    tags = {
            Name = "mgmt_ec2_vpn"
            
            env ="mgmt"
        }
    }

        resource "aws_instance" "mgmt_ec2_ca" {
    
    subnet_id = aws_subnet.mgmt_public_subnet_1.id
    instance_type = "t3.medium" 
    ami = "ami-0c7217cdde317cfec"
    key_name = aws_key_pair.mgmt_key.key_name

    tags = {
            Name = "mgmt_ec2_ca"
            
            env ="mgmt"
        }
    }

        resource "aws_instance" "mgmt_ec2_jenkins" {
    
    subnet_id = aws_subnet.mgmt_public_subnet_1.id
    instance_type = "r5.2xlarge" 
    ami = "ami-0c7217cdde317cfec"
    key_name = aws_key_pair.mgmt_key.key_name

    tags = {
            Name = "mgmt_ec2_jenkins"
            
            env ="mgmt"
        }
    }

resource "aws_lb" "mgmt_alb_jenkins" {
    
  subnets = [
      aws_subnet.mgmt_public_subnet_1.id,
      aws_subnet.mgmt_public_subnet_2.id,
      aws_subnet.mgmt_public_subnet_3.id
    ]

  tags = {
    Name = "mgmt_alb_jenkins"
    env  = "mgmt"
  }
}
      
    