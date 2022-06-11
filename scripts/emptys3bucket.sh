#!/bin/bash


aws s3 rm s3://$1 --recursive

read -p "Do you want to delete S3 Bucket? (yes/no):" answer
if [[ "$answer" == "yes" ]];
then
    echo "Deleting S3 bucket: $1"
    aws s3api delete-bucket --bucket $1 --region us-east-1
fi
  
exit