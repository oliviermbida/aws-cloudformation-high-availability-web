#!/bin/bash

# Author : Olivier Mbida (olivier.mbida@ai-uavsystems.com)
#
# Description:
# You can use this script to UPDATE an existing stack with a change-set by specifying the stack Id(ARN).
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
# ./update.sh [stack-name] [parameters] \
# [change-set-name]  
#
# Example to create a new template:
# ./update.sh cfnStacks ../templates/test_param.json test-change
#
# Notes:
# This scripts does not resolve any errors your CloudFormation templates may have.
# Those errors will be thrown in the console output by the AWS Cli for you to resolve.
# There is also no attempt to check if your S3 bucket exist. 
# You may get a ListObjectsV2 operation error thrown by the AWS Cli.
# Meaning your bucket does not exist.
####################################################################################################################

source ./change.sh $1 ../templates/stacks.yaml $2 $3 UPDATE