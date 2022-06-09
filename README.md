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

## Solution details
- Prerequisites:
    - Amazon AWS Account
    - AWS CLI v2
    - Create a key pair using Amazon EC2 from AWS CLI

        `aws ec2 create-key-pair --key-name key_pair --key-type  ed25519         
            --key-format pem --query "KeyMaterial" --output text > key_pair.pem`
    
    - Set the permissions of your key file
    `chmod 400 key_pair.pem`

## Building the Network
- The issue of multi-account [Availability zones mapping](https://aws.amazon.com/premiumsupport/knowledge-center/vpc-map-cross-account-availability-zones/). I will be creating subnets using the AvailabilityZoneId property rather than
using [!GetAZs](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getavailabilityzones.html) to obtain your availabilty zone names which may not match the unique zone Ids in your multi-account.
- For this reason I will use two matching parameters in my stack creation to deal with this issue. The VpcAzs and AzsMap parameters. It guarantees that the unique Availability Zones Ids are always used even if their Availability Zones names are different in your various account.
    - VpcAzs parameter is a list of Availability Zones in the form "0,use1-az2,0,use1-az4,0,0" for zones 2 and 4 in the region us-east-1. Zeros inserted as a placeholder for the unused zones. The format is for up to six zones.
    - AzsMap parameter is a map matching VpcAzs in the form "0,2,0,4,0,0" to match zones 2 and 4. Zeros inserted as a placeholder for the unused zones. Why another parameter? It is needed to set Conditions to match VpcAzs parameter.
    - A script Azs.sh is provided to query the Availabilty Zones for any Region. This is used to populate the two parameters.

            `aws ec2 describe-availability-zones \
        --region $Region --query "AvailabilityZones[?GroupName=='$Region'].ZoneId"`
        
    $Region (e.g us-east-1)


## Web Application 

## Testing


## Teardown


## Credits
