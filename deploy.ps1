Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

make deploy-dev

$profile = "serverless-flask-dev"
$devIamUser = jq -r '.serverless-flask-dev.devIamUser' cdk.out/dev-stage-output.json
$creds = aws iam create-access-key --user-name $devIamUser --output json
aws configure set aws_access_key_id $(echo $creds | jq -r '.AccessKey.AccessKeyId') --profile $profile
aws configure set aws_secret_access_key $(echo $creds | jq -r '.AccessKey.SecretAccessKey') --profile $profile
aws configure set output json --profile $profile