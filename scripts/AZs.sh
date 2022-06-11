#!/bin/bash

aws ec2 describe-availability-zones \
--region "$1" --query "AvailabilityZones[?GroupName=='$1'].ZoneId"