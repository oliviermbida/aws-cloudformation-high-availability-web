aws cloudformation  delete-change-set \
--change-set-name $1 \
#[--stack-name <value>]
#[--cli-input-json <value>]
#[--generate-cli-skeleton <value>]

aws cloudformation  delete-stack-set \
--stack-set-name $1 \
#[--call-as <value>]
#[--cli-input-json <value>]
#[--generate-cli-skeleton <value>]

aws cloudformation  delete-stack --stack-name $1
#[--retain-resources <value>]
#[--role-arn <value>]
#[--client-request-token <value>]
#[--cli-input-json <value>]
#[--generate-cli-skeleton <value>]


aws cloudformation delete-stack-instances --stack-set-name my-awsconfig-stackset --accounts '["0123456789012"]' --regions '["eu-west-1"]' --operation-preferences FailureToleranceCount=0,MaxConcurrentCount=1 --no-retain-stacks
aws cloudformation delete-stack-instances --stack-set-name my-awsconfig-stackset --deployment-targets OrganizationalUnitIds='["ou-rcuk-1x5jlwo", "ou-rcuk-slr5lh0a"]' --regions '["eu-west-1"]' --no-retain-stacks
aws cloudformation describe-stack-set-operation --stack-set-name stackSetName --operation-id ddf16f54-ad62-4d9b-b0ab-3ed8e9example

aws cloudformation delete-stack-set --stack-set-name my-awsconfig-stackset
aws cloudformation list-stack-sets
aws iam delete-role --role-name role name

