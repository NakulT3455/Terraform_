terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region     = "ap-south-1"
  access_key = "AKIAV52ISMUNI5KVCKTN"
  secret_key = "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"
}

resource "aws_vpc" "VPC" {
  cidr_block = "10.0.0.0/27"
}

resource "aws_subnet" "Public_Subnet" {
  vpc_id     = aws_vpc.VPC.id
  cidr_block = "10.0.0.0/28"

}

resource "aws_subnet" "Private_Subnet" {
  vpc_id     = aws_vpc.VPC.id
  cidr_block = "10.0.0.16/28"

}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.VPC.id
}


resource "aws_eip" "eip" {
  vpc      = "true"

}

resource "aws_nat_gateway" "NAT_Gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.Public_Subnet.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.VPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.Public_Subnet.id
  route_table_id = aws_route_table.public_route_table.id
}


resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.VPC.id

    route {
          cidr_block = "0.0.0.0/0"
          gateway_id = aws_nat_gateway.NAT_Gateway.id
  }

}

resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.Private_Subnet.id
  route_table_id = aws_route_table.private_route_table.id
}


resource "aws_security_group" "Security_group" {

  vpc_id      = aws_vpc.VPC.id

  ingress {
    
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }


}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


resource "aws_lambda_function" "test_lambda" {

  filename      = "lambda.zip"
  function_name = "lambda_function_name"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda.lambda_function"

  runtime = "python3.7"

   environment {
    variables = {
      Subnet = aws_subnet.Private_Subnet.id
    }
  }
  
}

























