
    //////// prd Env ///////////


    resource "aws_vpc" "prd_vpc" {
      cidr_block = "10.1.0.0/16"
      enable_dns_support = true
      enable_dns_hostnames = true

      tags = {
        Name = "prd_vpc"
        
        env ="prd"
      }
    }

    resource "aws_internet_gateway" "prd_ig" {
      vpc_id = aws_vpc.prd_vpc.id

      tags = {
        Name = "prd_ig"
        
        env ="prd"
      }
    }

    resource "aws_subnet" "prd_public_subnet_1" {
      vpc_id = aws_vpc.prd_vpc.id
      cidr_block              = "10.1.1.0/24"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = true

      tags = {
        Name = "prd_Public Subnet_1"
        env ="prd"
      }
    }

    resource "aws_subnet" "prd_public_subnet_2" {
          vpc_id = aws_vpc.prd_vpc.id
          cidr_block              = "10.1.2.0/24"
          availability_zone       = "us-east-1b"
          map_public_ip_on_launch = true

          tags = {
            Name = "prd_Public Subnet_2"
            env ="prd"
          }
        }


    resource "aws_subnet" "prd_public_subnet_3" {
          vpc_id = aws_vpc.prd_vpc.id
          cidr_block              = "10.1.3.0/24"
          availability_zone       = "us-east-1c"
          map_public_ip_on_launch = true
          
          tags = {
            Name = "prd_Public Subnet_3"
            
            env ="prd"
          }
        }

    resource "aws_subnet" "prd_private_subnet_1" {
          vpc_id = aws_vpc.prd_vpc.id
          cidr_block              = "10.1.4.0/24"
          availability_zone       = "us-east-1a"
          
          tags = {
            Name = "prd_private Subnet_1"
            
            env ="prd"
          }
        }
    resource "aws_subnet" "prd_private_subnet_2" {
          vpc_id = aws_vpc.prd_vpc.id
          cidr_block              = "10.1.5.0/24"
          availability_zone       = "us-east-1b"
       
          tags = {
            Name = "prd_private Subnet_1"
            
            env ="prd"
          }
        }
    resource "aws_route_table" "prd_route_table_public" {
      vpc_id = aws_vpc.prd_vpc.id
      route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.prd_ig.id
      }
      tags = {
        Name = "prd_route_table_public"
        
        env ="prd"
      }
    }

    resource "aws_route_table_association" "prd_a" {
      subnet_id      = aws_subnet.prd_public_subnet_1.id
      route_table_id = aws_route_table.prd_route_table_public.id
    }
    resource "aws_route_table_association" "prd_b" {
      subnet_id      = aws_subnet.prd_public_subnet_2.id
      route_table_id = aws_route_table.prd_route_table_public.id
    }
    resource "aws_route_table_association" "prd_c" {
      subnet_id      = aws_subnet.prd_public_subnet_3.id
      route_table_id = aws_route_table.prd_route_table_public.id
    }

resource "aws_db_subnet_group" "prd_db_subnet_group" {
  name       = "prd-db-subnet-group"
  subnet_ids = [aws_subnet.prd_private_subnet_1.id,aws_subnet.prd_private_subnet_2.id]
  tags = {
   Name="prd_db_subnet_group"
    env ="prd"
  }
}

resource "aws_elasticache_subnet_group" "prd_ec_subnet_group" {
  name       = "prd-ec-subnet-group"
  subnet_ids = [aws_subnet.prd_private_subnet_1.id,aws_subnet.prd_private_subnet_2.id]
  tags = {
   Name= "prd_ec_subnet_group"
    env ="prd"
  }
}



resource "aws_eip" "prd_eip" {
  domain = "vpc"
  tags = {
   
    env ="prd"
  }
}
resource "aws_nat_gateway" "prd_nat_gateway" {
    subnet_id = aws_subnet.prd_public_subnet_1.id
    allocation_id = aws_eip.prd_eip.id
    tags = {
        Name= "prd_nat_gateway"
   
    env ="prd"
  }
  
}

    resource "aws_key_pair" "prd_key" {
       key_name = "prd_key"
      public_key = tls_private_key.prd_rsa_key.public_key_openssh
      tags = {
        env ="prd"
      }
    }

    resource "tls_private_key" "prd_rsa_key" {
      algorithm = "RSA"
      rsa_bits  = 4096
    }

    resource "local_file" "prd_key" {
    content  = tls_private_key.prd_rsa_key.private_key_pem
    filename = "prd_key.pem"
    }



   
resource "aws_security_group" "prd_sg" {
      vpc_id = aws_vpc.prd_vpc.id

       tags = {
        Name = "prd_sg"
        
    env ="prd"
      }
    }

 resource "aws_db_instance" "prd_rds" {
 
  identifier           = "prd-rds"
  instance_class       = "db.r5.2xlarge"

  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  username             = "root"
  password             = "admin1234"
  publicly_accessible = false
  multi_az             = true
  max_allocated_storage = 1000
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true

  vpc_security_group_ids = [aws_security_group.prd_sg.id]
  db_subnet_group_name = aws_db_subnet_group.prd_db_subnet_group.name
  tags = {
    Name = "prd_rds"
    env ="prd"
  }
}





resource "aws_elasticache_replication_group" "prd_redis_group" {
      replication_group_id        = "prd-redis-cache"
      node_type            = "cache.r5.2xlarge"
      description = "prd_redis_group"
      parameter_group_name = "default.redis7.cluster.on"
      automatic_failover_enabled  = true
      multi_az_enabled = true
     subnet_group_name = aws_elasticache_subnet_group.prd_ec_subnet_group.name
      num_node_groups         = 1
      replicas_per_node_group = 1
   
}


module "prd_eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = "prd_eks_cluster"
  cluster_endpoint_public_access  = true
  cluster_version = "1.29"
  enable_cluster_creator_admin_permissions = true

  vpc_id          = aws_vpc.prd_vpc.id
  subnet_ids      = [
    aws_subnet.prd_public_subnet_1.id,
    aws_subnet.prd_public_subnet_2.id,
    aws_subnet.prd_public_subnet_3.id
  ]



 eks_managed_node_groups = {
    prd_nodes = {
      min_size     = 2
      max_size     = 10
      desired_size = 2
      instance_types = ["c5.2xlarge"]
    }
  }

  tags = {
    Terraform   = "true"
    Name ="prd_eks_cluster"
     env ="prd"
  }
}
