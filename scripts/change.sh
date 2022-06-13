#!/bin/bash

# Author : Olivier Mbida (olivier.mbida@ai-uavsystems.com)
#
# Description:
# You can use this script to UPDATE an existing stack with a change-set by specifying the stack Id(ARN).
# You can CREATE a new stack with a change-set and executing it so that the newly created 
# stack does not remain on a REVIEW_IN_PROGRESS status without any attached template or resources.
#
# This script follows a workflow as follows:
#   - Clean up existing files locally and in S3 bucket if they exists.
#   - Package templates and upload to S3 bucket.
#   - Create change-set for new or existing stack.
#   - Review changes if updating existing stack.
#   - Execute change-set and monitor events.
#
# Prerequisites
# - This script assumes that you have installed and configured the AWS Cli with your account details.
# - It also assumes that you have a publicly available S3 bucket and you have the priviledges to upload to it.
# - Helper scripts:
#   - emptys3bucket.sh : Deletes all files in your S3 bucket and optionally deletes the bucket.
#   - package.sh :  Packages the nested stacks artifacts and uploads to S3 bucket. 
#                   Creates the template [stacks-packaged.yaml] locally which is used to create the change-set.
# Example Usage:
#
# ./change.sh [stack-name] [template-body] [parameters] \
# [change-set-name] [change-set-type] 
#
# Example to update an existing template:
# ./change.sh test-stack ../templates/stacks.yaml ../templates/test_param.json test-change-set UPDATE
#
# Notes:
# This scripts does not resolve any errors your CloudFormation templates may have.
# Those errors will be thrown in the console output by the AWS Cli for you to resolve.
# There is also no attempt to check if your S3 bucket exist. 
# You may get a ListObjectsV2 operation error thrown by the AWS Cli.
# Meaning your bucket does not exist.
####################################################################################################################

# Options to name your packaged stacks and your S3 bucket
Package_stack=../templates/stacks-packaged.yaml
s3_bucket_name="your-s3-bucket"

#
if [ -f "$Package_stack" ]; then 
    echo "Deleting existing packaged stacks file: $Package_stack"
    rm $Package_stack
fi 
echo "Deleting existing packaged stacks files in S3 Bucket"
(./emptys3bucket.sh $s3_bucket_name)
echo "Packaging Stacks $2"
echo "..."
(./package.sh $2 $s3_bucket_name)

# Wait for local file
while [ ! -f "$Package_stack" ] ; do
    read -n 1 key <&1
    if [[ $key = q ]] ; then
        echo "Exit: $Package_stack not found."
        exit ;
    else
        echo "Waiting for $Package_stack Press key [Q] to exit."
    fi
done


if [[ "$5" == "UPDATE" ]]; then 
    read -p "Please enter Stack Id (arn) to Update:" stackARN
    IFS= read change_set_ID << EOF
    $(aws cloudformation create-change-set \
    --stack-name $stackARN \
    --template-body file://$Package_stack \
    --parameters file://$3 \
    --change-set-name $4 \
    --change-set-type $5 \
    --capabilities CAPABILITY_IAM \
    --output text --query "Id")
EOF
    if [[ $change_set_ID == "" ]]; then
        echo "Could not create change-set."
        exit
    fi
else
    IFS= read change_set_ID << EOF
    $(aws cloudformation create-change-set \
    --stack-name $1 \
    --template-body file://$Package_stack \
    --parameters file://$3 \
    --change-set-name $4 \
    --change-set-type $5 \
    --capabilities CAPABILITY_IAM \
    --output text --query "Id")
EOF
    if [[ $change_set_ID == "" ]]; then
        echo "Could not create change-set."
        exit
    fi
fi 

echo "Change-set Id: $change_set_ID"
IFS= read stack_ID << EOF
$(aws cloudformation describe-stacks \
    --stack-name $1 \
    --output text --query "Stacks[0].StackId")
EOF
echo "Stack Id: $stack_ID"

if [[ $stack_ID == "" ]]; then
    echo "Could not create stack."
    exit
fi
# Review stack changes
change_set_Changes=$(aws cloudformation  describe-change-set --change-set-name $change_set_ID \
--query "Changes[]")
echo -e "Review Stack Changes:\n  $change_set_Changes"
sleep 5

read -p "Do you want to execute change-set? (yes/no):" answer1
if [[ "$answer1" = "yes" ]];
then
    echo "Executing change-set: $change_set_ID"
    aws cloudformation execute-change-set --change-set-name ${change_set_ID}
    while [ 1 ]   # Endless loop.
    do
        stack_Status=$(aws cloudformation describe-stacks \
            --stack-name $1 \
            --output text --query "Stacks[0].StackStatus")
        echo "Stack Status: $stack_Status"
        # stack_Status_complete=$(aws cloudformation describe-stacks --output text --query "Stacks[?contains(StackName,$1)].StackName")
        if [[ $stack_Status == "CREATE_COMPLETE" || $stack_Status == "UPDATE_COMPLETE"  ]]; then
            # echo "Stacks completed:\n $stack_Status_complete"
            echo "Exiting stack status: $stack_Status"
            exit
        elif [[ $stack_Status == "CREATE_FAILED" || $stack_Status == "ROLLBACK_IN_PROGRESS" || $stack_Status == "ROLLBACK_COMPLETE" || $stack_Status == "UPDATE_ROLLBACK_COMPLETE" || $stack_Status == "DELETE_IN_PROGRESS" ]]; then
            echo "Exiting stack status: $stack_Status"
            exit
        fi
        sleep 5
    done
else
    read -p "Do you want to delete change-set? (yes/no):" answer2
    if [[ "$answer2" == "yes" ]];
    then
        echo "Deleting change-set: $change_set_ID"
        aws cloudformation  delete-change-set --change-set-name $change_set_ID
    fi
    read -p "Do you want to delete stack? (yes/no):" answer3
    if [[ "$answer3" == "yes" ]];
    then
        echo "Deleting Stack..."
        aws cloudformation  delete-stack --stack-name $1
        echo "..."
        sleep 5

        IFS= read stack_Delete_Status << EOF
        $(aws cloudformation describe-stack-events \
            --stack-name $stack_ID --max-items 2 \
            --output text --query "StackEvents[0].ResourceStatus")
EOF

        echo "Stack Status: $stack_Delete_Status"
    else
        echo "Don't forget to teardown AWS resources if not needed:"
        echo "aws cloudformation  delete-stack --stack-name $1"
    fi
fi 