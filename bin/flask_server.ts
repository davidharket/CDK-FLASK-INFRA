#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { ServerlessFlaskStack } from '../lib/flask_server-stack';

const app = new cdk.App();
const stackName = ({
  "dev": "serverless-flask-dev",
  "staging": "serverless-flask-staging",
  "prod": "serverless-flask-prod"
}as Record<string, string>)[app.node.tryGetContext("stage") as string];
new ServerlessFlaskStack(app, 'ServerlessFlask', {
  stackName: stackName,
  env: { account: process.env.CDK_DEFAULT_ACCOUNT, region: process.env.CDK_DEFAULT_REGION },
});