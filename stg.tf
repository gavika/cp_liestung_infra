
    //////// Stg Env ///////////


    resource "aws_vpc" "stg_vpc" {
      cidr_block = "10.0.0.0/16"
      enable_dns_support = true
      enable_dns_hostnames = true

      tags = {
        Name = "stg_vpc"
        
        env ="stg"
      }
    }

    resource "aws_internet_gateway" "stg_ig" {
      vpc_id = aws_vpc.stg_vpc.id

      tags = {
        Name = "stg_ig"
        
        env ="stg"
      }
    }

    resource "aws_subnet" "stg_public_subnet_1" {
      vpc_id = aws_vpc.stg_vpc.id
      cidr_block              = "10.0.1.0/24"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = true

      tags = {
        Name = "stg_Public Subnet_1"
        env ="stg"
      }
    }

    resource "aws_subnet" "stg_public_subnet_2" {
          vpc_id = aws_vpc.stg_vpc.id
          cidr_block              = "10.0.2.0/24"
          availability_zone       = "us-east-1b"
          map_public_ip_on_launch = true

          tags = {
            Name = "stg_Public Subnet_2"
            env ="stg"
          }
        }


    resource "aws_subnet" "stg_public_subnet_3" {
          vpc_id = aws_vpc.stg_vpc.id
          cidr_block              = "10.0.3.0/24"
          availability_zone       = "us-east-1c"
          map_public_ip_on_launch = true
          
          tags = {
            Name = "stg_Public Subnet_3"
            
            env ="stg"
          }
        }

    resource "aws_subnet" "stg_private_subnet_1" {
          vpc_id = aws_vpc.stg_vpc.id
          cidr_block              = "10.0.4.0/24"
          availability_zone       = "us-east-1a"
          
          tags = {
            Name = "stg_private Subnet_1"
            
            env ="stg"
          }
        }
    resource "aws_subnet" "stg_private_subnet_2" {
          vpc_id = aws_vpc.stg_vpc.id
          cidr_block              = "10.0.5.0/24"
          availability_zone       = "us-east-1b"
       
          tags = {
            Name = "stg_private Subnet_1"
            
            env ="stg"
          }
        }
    resource "aws_route_table" "stg_route_table_public" {
      vpc_id = aws_vpc.stg_vpc.id
      route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.stg_ig.id
      }
      tags = {
        Name = "stg_route_table_public"
        
        env ="stg"
      }
    }

    resource "aws_route_table_association" "stg_a" {
      subnet_id      = aws_subnet.stg_public_subnet_1.id
      route_table_id = aws_route_table.stg_route_table_public.id
    }
    resource "aws_route_table_association" "stg_b" {
      subnet_id      = aws_subnet.stg_public_subnet_2.id
      route_table_id = aws_route_table.stg_route_table_public.id
    }
    resource "aws_route_table_association" "stg_c" {
      subnet_id      = aws_subnet.stg_public_subnet_3.id
      route_table_id = aws_route_table.stg_route_table_public.id
    }

resource "aws_db_subnet_group" "stg_db_subnet_group" {
  name       = "stg-db-subnet-group"
  subnet_ids = [aws_subnet.stg_private_subnet_1.id,aws_subnet.stg_private_subnet_2.id]
  tags = {
   Name="stg_db_subnet_group"
    env ="stg"
  }
}

resource "aws_elasticache_subnet_group" "stg_ec_subnet_group" {
  name       = "stg-ec-subnet-group"
  subnet_ids = [aws_subnet.stg_private_subnet_1.id,aws_subnet.stg_private_subnet_2.id]
  tags = {
   Name= "stg_ec_subnet_group"
    env ="stg"
  }
}



resource "aws_eip" "stg_eip" {
  domain = "vpc"
  tags = {
   
    env ="stg"
  }
}
resource "aws_nat_gateway" "stg_nat_gateway" {
    subnet_id = aws_subnet.stg_public_subnet_1.id
    allocation_id = aws_eip.stg_eip.id
    tags = {
        Name= "stg_nat_gateway"
   
    env ="stg"
  }
  
}

    resource "aws_key_pair" "stg_key" {
       key_name = "stg_key"
      public_key = tls_private_key.stg_rsa_key.public_key_openssh
      tags = {
        env ="stg"
      }
    }

    resource "tls_private_key" "stg_rsa_key" {
      algorithm = "RSA"
      rsa_bits  = 4096
    }

    resource "local_file" "stg_key" {
    content  = tls_private_key.stg_rsa_key.private_key_pem
    filename = "stg_key.pem"
    }



   
resource "aws_security_group" "stg_sg" {
      vpc_id = aws_vpc.stg_vpc.id

       tags = {
        Name = "stg_sg"
        
    env ="stg"
      }
    }

 resource "aws_db_instance" "stg_rds" {
 
  identifier           = "stg-rds"
   instance_class       = "db.t3.micro"

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

  vpc_security_group_ids = [aws_security_group.stg_sg.id]
  db_subnet_group_name = aws_db_subnet_group.stg_db_subnet_group.name
  tags = {
    Name = "stg_rds_t3_micro"
    env ="stg"
  }
}

resource "aws_elasticache_replication_group" "stg_redis_group" {
      replication_group_id        = "stg-redis-cache"
      node_type            = "cache.t3.micro"
      description = "stg_redis_group"
      parameter_group_name = "default.redis7.cluster.on"
      automatic_failover_enabled  = true
      multi_az_enabled = true
     subnet_group_name = aws_elasticache_subnet_group.stg_ec_subnet_group.name
      num_node_groups         = 1
      replicas_per_node_group = 1
   tags = {
    env = "stg"
   }
}


module "stg_eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = "stg_eks_cluster"
  cluster_endpoint_public_access  = true
  cluster_version = "1.29"
  enable_cluster_creator_admin_permissions = true

  vpc_id          = aws_vpc.stg_vpc.id
  subnet_ids      = [
    aws_subnet.stg_public_subnet_1.id,
    aws_subnet.stg_public_subnet_2.id,
    aws_subnet.stg_public_subnet_3.id
  ]



 eks_managed_node_groups = {
    stg_nodes = {
      min_size     = 2
      max_size     = 10
      desired_size = 2
     
    }
  }

  tags = {
    Terraform   = "true"
    Name ="stg_eks_cluster"
     env ="stg"
  }
}
