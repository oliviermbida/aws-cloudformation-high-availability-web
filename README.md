# Deploy a high-availability web app using CloudFormation
In this project, I will build the infrastructure to host a high availability web application using AWS CloudFormation.
## Project Overview
    ### Network
    - A VPC with public and private subnets, spanning an AWS region.
    - Public and Private subnet in every Availability Zones chosen. 
    - Internet Gateway for inbound and outbound traffic in the VPC.
    - NAT Gateway in every Availability Zones for internet access for web application servers in private subnets.
    - A VPC endpoint gateway for S3 Bucket access for web application servers in private subnets.
    - An Application Load Balancer (ALB) in public subnets for internet traffic to web application servers in private subnets

    ### Web Application
    - An Auto Scaling Group for EC2 instances in private subnets
    - S3 Bucket for VPC endpoint access by web servers in private subnets

    ### Testing
    - A Bastion EC2 instance in public subnets for SSH connections to web servers in private subnets.
    - A Load Auto Scaling Group to test the Application Load Balancer

- Prerequisites:
    - Amazon AWS Account
    - AWS CLI v2
    - Create a key pair using Amazon EC2 from AWS CLI

    `aws ec2 create-key-pair \`
        `--key-name key_pair \`
        `--key-type  ed25519 \`
        `--key-format pem \`
        `--query "KeyMaterial" \`
        `--output text > key_pair.pem`
    
    - Set the permissions of your key file
    `chmod 400 key_pair.pem`
    - Start Ssh agent
    `eval "$(ssh-agent -s)"`
    - Add key to agent
    `ssh-add ~/.ssh/key_pair`

## Solution overview

![AWS Architecture diagram](/docs/images/cfn_arch.png)

## Solution details
## Building the Network


## Web Application 

## Testing


## Teardown


## Credits
