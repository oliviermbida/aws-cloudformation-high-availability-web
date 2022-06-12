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
7. Optional cloudfront distribution to serve the web application.

## Solution preview

[Application Load Balancer Endpoint](http://cfnst-publi-16ukdq2zg6cqp-79202707.us-east-1.elb.amazonaws.com/)

[Cloudfront Endpoint](http://d1rbo8udt2f2sz.cloudfront.net/)

## Solution details

If you do not want to follow the solution steps below, you can deploy the cloudformation stacks with *your-stack-name* and *your-parameters* using *your-s3-bucket* in the command:

    `make deploy stack-name=your-stack-name parameters=your-parameters s3-bucket=your-s3-bucket`

A sample parameters template *stacks_param.json* is provided in the templates folder.

If you want to update any of the stack templates :

    - network_vpc.yaml
    - network_sgs.yaml
    - webApp_Asg.yaml
    - webApp_Alb.yaml
    - webApp_cdn.yaml
    - webApp_r53.yaml

You can package using *your-s3-*bucket* and the output is *./templates/stacks-packaged.yaml* before deploying:

    `make package s3-bucket=your-s3-bucket`

Alternatively the workflow uses the top level stack template *stacks.yaml* for updates using *your-change-set*:

    `make update stack-name=your-stack-name parameters=your-parameters changes=your-change-set`

Or first use the workflow to create *your-stack-name* with *your-parameters* and *your-change-set*:

    `./scripts/create.sh your-stack-name your-parameters your-change-set`

Don't forget to teardown any resources if not required.

    `make clean stack-name=your-stack-name`

Please note that this command will delete all resources created with the top level stack *stacks.yaml* unless you've added your own resource retention policies.

These commands assume that you have installed and configured AWS CLI with your account details.

- Prerequisites:
    - Amazon AWS Account
    - AWS CLI v2
    - Create a key pair using Amazon EC2 from AWS CLI

        `aws ec2 create-key-pair --key-name my_ec2_key_pair --key-type  ed25519         
            --key-format pem --query "KeyMaterial" --output text > my_ec2_key_pair.pem`
    
    - Set the permissions of your key file

    `chmod 400 my_ec2_key_pair.pem`

    - A linux platform

## Building the Network
- The issue of multi-account [Availability zones mapping](https://aws.amazon.com/premiumsupport/knowledge-center/vpc-map-cross-account-availability-zones/). I will be creating subnets using the AvailabilityZoneId property rather than
using [!GetAZs](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getavailabilityzones.html) to obtain your availabilty zone names which may not match the unique zone Ids in your multi-account.
- For this reason I will use two matching parameters in my Cloudformation stack creation to deal with this issue. The VpcAzs and AzsMap parameters. It guarantees that the unique Availability Zones Ids are always used even if their Availability Zones names are different in your various account.
    - VpcAzs parameter is an ordered list of Availability Zones in the form *["0,use1-az2,0,use1-az4,0,0"]* for zones 2 and 4 in the region us-east-1. Zeros inserted as a placeholder for the unused zones. The format is for up to six zones.
    - AzsMap parameter is a map matching the ordered VpcAzs in the form *["0,2,0,4,0,0"]* to match zones 2 and 4. Zeros inserted as a placeholder for the unused zones. Why another parameter? It is needed to set Conditions to match VpcAzs parameter.
    - A script Azs.sh is provided to query the Availabilty Zones for any Region. This is used to populate the two parameters. e.g for us-east-1

            `aws ec2 describe-availability-zones --region us-east-1 --query "AvailabilityZones[?GroupName=='us-east-1'].ZoneId"`

- The workflow I will use is that of creating Cloudformation change sets before updating stacks which is detailed in the script create.sh
- I will also use a nested or tier stack approach with the top stack template called stacks.yaml
- The Cloudformation templates to build the layers of the network are in:
    - network_vpc.yaml

    Through a granular approach using change sets I will add the pieces in the *network_vpc.yaml* template.

    - Vpc
    - Subnets
    - Internet gateway and public subnets routing
    - Nat gateways, Elastic IPs and private subnets routing
    - Additional firewall around subnets with network access control lists (acls)
    - Vpc S3 endpoint gateway

    At each stage a simple command will add the pieces:

        `make update stack-name=your-stack-name parameters=your-parameters changes=your-change-set`

    ![Network Vpc stack image](/docs/images/network_vpc.png)

- Lets do our first tests to verify that the resources in the public and private subnets have access to the internet through Http port 80 via routing to Nat gateways and the Internet gateway. Secondly I will also check that the S3 Vpc endpoint is working by downloading from a bucket while in private subnets.
    - To do this I will ssh into a Bastion (EC2 instance) in public subnets and get access to a test EC2 instance launched in private subnets.

    - Since I am now going to add resources in the network, I will setup security groups around those resources.
        - network_sgs.yaml (security groups)
        - network_bastion.yaml (resource in public subnet)
        - webApp_test.yaml (resource in private subnet)

    - The command to get into the bastion is something like (for linux):

        ssh -i my_ec2_key_pair -A $(user)@ec2-$(instance_public_ip).compute-1.amazonaws.com

    - Once in the bastion, to test internet:

        telnet google.com 80

    - You will get an ESC response from google servers confirming you have internet connection on port 80.

    - Next ssh to the EC2 instance (linux) launched in private subnets.

        ssh -i my_ec2_key_pair -A $(user)@$(instance_private_ip)

    - Note that my_ec2_key_pair was copied into the bastion (set permission chmod 400 on the key)
    and use it to get into the ec2 linux instance launched in private subnets.
    Once there repeat the telnet test on google.com port 80.

    - Now get the url of a file in a bucket and download.

        `wget https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-py3-latest.tar.gz`

    The S3 Vpc endpoint added a route to the specified route table to direct any S3 prefix list traffic (ip addresses) to the Vpc gateway endpoint not through the Nat gateway or Internet gateway. This can save the costs of using Nat gateways.


    ![Network http80 test ](/docs/images/webApp_test_http80.png)

    ![Network vpce test ](/docs/images/test_network_vpce.png)

    [Other tests screenshots](/docs/images/)

## Web Application 
- Following the success in testing a bastion and a test web app auto scaling group in private subnet, I will now add a UserData script to the web App to launch an apache2 web server and I will also download webApp files from an S3 bucket.

         `UserData:
            Fn::Base64:
            !Sub |
                Content-Type: multipart/mixed; boundary="//"
                MIME-Version: 1.0

                --//
                Content-Type: text/cloud-config; charset="us-ascii"
                MIME-Version: 1.0
                Content-Transfer-Encoding: 7bit
                Content-Disposition: attachment; filename="cloud-config.txt"

                #cloud-config
                cloud_final_modules:
                - [scripts-user, always]

                --//
                Content-Type: text/x-shellscript; charset="us-ascii"
                MIME-Version: 1.0
                Content-Transfer-Encoding: 7bit
                Content-Disposition: attachment; filename="userdata.txt"
                #!/bin/bash -xe
                apt-get update -y
                apt-get install -y apache2
                touch /etc/apache2/sites-available/webapp.conf
                echo 'ServerName 127.0.0.1:80' >> /etc/apache2/sites-available/webapp.conf
                echo 'DocumentRoot /var/www/webapp' >> /etc/apache2/sites-available/webapp.conf
                echo '<Directory /var/www/webapp>' >> /etc/apache2/sites-available/webapp.conf
                echo '  Options Indexes FollowSymLinks' >> /etc/apache2/sites-available/webapp.conf
                echo '  AllowOverride All' >> /etc/apache2/sites-available/webapp.conf
                echo '  Require all granted' >> /etc/apache2/sites-available/webapp.conf
                echo '</Directory>' >> /etc/apache2/sites-available/webapp.conf
                cd /tmp/
                wget https://${S3BucketName}.s3.amazonaws.com/webApp/files.txt  
                wget -i files.txt -P /var/www/webapp          
                a2ensite webapp
                a2dissite 000-default
                systemctl reload apache2
                --//--`

Please note that I am using an AMI with Ubuntu Server 20.04 LTS for testing.

    - ${S3BucketName} Policy (needed for wget to download the S3 bucket folder webApp)
        `{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "AllowObjectDownloadRoot",
                    "Effect": "Allow",
                    "Principal": "*",
                    "Action": "s3:GetObject",
                    "Resource": "arn:aws:s3:::${S3BucketName}/*"
                },
                {
                    "Sid": "AllowListFolders",
                    "Effect": "Allow",
                    "Principal": "*",
                    "Action": "s3:ListBucket",
                    "Resource": "arn:aws:s3:::${S3BucketName}",
                    "Condition": {
                        "StringEquals": {
                            "s3:delimiter": "/",
                            "s3:prefix": [
                                "",
                                "webApp"
                            ]
                        }
                    }
                },
                {
                    "Sid": "AllowListFolderFiles",
                    "Effect": "Allow",
                    "Principal": "*",
                    "Action": "s3:ListBucket",
                    "Resource": "arn:aws:s3:::${S3BucketName}",
                    "Condition": {
                        "StringLike": {
                            "s3:prefix": "webApp/*"
                        }
                    }
                },
                {
                    "Sid": "AllowObjectDownloadFolder",
                    "Effect": "Allow",
                    "Principal": "*",
                    "Action": "s3:GetObject",
                    "Resource": "arn:aws:s3:::${S3BucketName}/webApp/*"
                }
            ]
        }`
        

- Next I will add the application load balancer to test the apache2 server with a public IP address and update the web app auto scaling group to max: 5 and min: 2. I will also add the security groups for the load balancer.

    ![Network Alb test ](/docs/images/webApp_test_alb.png)

    ![Network Alb dns ](/docs/images/test_network_alb_dns.png)

    ![Network Alb dns ](/docs/images/test_network_asg.png)

## Testing


## Teardown


## Credits
