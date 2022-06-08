# Deploy a high-availability web app using CloudFormation
In this project, I will build the infrastructure to host a high availability web application using [AWS CloudFormation best practices](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html).

## Solution overview

![AWS Architecture diagram](/docs/images/cfn_arch.png)

1. An Internet Gateway allows inbound and outbound traffic to resources in the VPC.
2. An Application Load Balancer to distrubute internet traffic across web application auto scaling group.
3. Network Access Control Lists as a firewall to restrict internet traffic at the public and private subnets level.
4. Nat gateways and an Elastic IP in public subnets for internet access by web application servers in private subnets.
5. Web application servers run as Auto Scaling Group of EC2 instances in private subnets with a security group.
6. A Vpc endpoint gateway to an S3 bucket service. Web application servers access to the service from private subnets are routed to this gateway endpoint to avoid the Nat gateways charges.

## Network
    - A VPC with public and private subnets, spanning an AWS region.
    - Public and Private subnet in every Availability Zones chosen. 
    - Internet Gateway for inbound and outbound traffic in the VPC.
    - NAT Gateway in every Availability Zones for internet access for web application servers in private subnets.
    - A VPC endpoint gateway for S3 Bucket access by web application servers in private subnets.
    - An Application Load Balancer (ALB) in public subnets for internet traffic to web application servers in private subnets.

## Web Application
    - An Auto Scaling Group of EC2 instances in private subnets.
    - S3 Bucket service as a VPC endpoint access by web servers in private subnets.

## Testing
    - A Bastion EC2 instance in public subnets for SSH connections to web servers in private subnets.
    - A Load Auto Scaling Group to test the Application Load Balancer.


## Solution details
- Prerequisites:
    - Amazon AWS Account
    - AWS CLI v2
    - Create a key pair using Amazon EC2 from AWS CLI

        `aws ec2 create-key-pair --key-name key_pair --key-type  ed25519         
            --key-format pem --query "KeyMaterial" --output text > key_pair.pem`
    
    - Set the permissions of your key file
    `chmod 400 key_pair.pem`
    - Start Ssh agent
    `eval "$(ssh-agent -s)"`
    - Add key to agent
    `ssh-add ~/.ssh/key_pair`

## Building the Network


## Web Application 

## Testing


## Teardown


## Credits
