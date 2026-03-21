# IAM Roles and Permissions

## Overview
This document describes all IAM roles created by this infrastructure.

## Roles

### 1. EC2 Instance Role (`${project_name}-ec2-role`)
**Purpose**: Allows EC2 instances to interact with AWS services
**Permissions**:
- DynamoDB: Read/write access to metrics table
- SSM: Systems Manager access for instance management

### 2. CodeBuild Role (`${project_name}-codebuild-role`)
**Purpose**: Allows CodeBuild to build and push Docker images
**Permissions**:
- ECR: Push/pull images
- S3: Read/write artifacts
- CloudWatch: Write logs

### 3. CodePipeline Role (`${project_name}-pipeline-role`)
**Purpose**: Orchestrates the CI/CD pipeline
**Permissions**:
- S3: Read/write artifacts
- CodeBuild: Start builds
- IAM: Pass roles

### 4. CodeDeploy Role (`${project_name}-codedeploy-role`)
**Purpose**: Deploys applications to EC2/ASG
**Permissions**:
- EC2: Describe instances
- ASG: Update auto-scaling groups
- ELB: Register/deregister targets

### 5. AWS Config Role (`${project_name}-config-role`)
**Purpose**: Records resource configurations
**Permissions**:
- Full AWS Config access
- S3: Write configuration snapshots

### 6. AWS Backup Role (`${project_name}-backup-role`)
**Purpose**: Performs automated backups
**Permissions**:
- DynamoDB: Backup tables
- S3: Backup buckets