#!/bin/bash

aws cloudformation package --template-file $1 --s3-bucket $2 --output-template-file ../templates/stacks-packaged.yaml 

exit