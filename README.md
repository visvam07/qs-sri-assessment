# [Sri's Quantspark Assessment]

The objective of this project is to showcase the deployment of a highly available simple web application using Terraform on AWS Public Cloud infrastructure.

## Repository Structure

```
Repository Root
│
├── app/
│   ├── (application files and directories...)
│
└── terraform/
    ├── (terraform files and directories...)
```

### `app/`
This directory houses all the application-related code, including the core logic, functionalities, and assets of the web application.

### `terraform/`
Within this directory are all Terraform-related configurations, dedicated to provisioning and managing the cloud infrastructure required to run the application.

## Prerequisites

Before you begin, ensure you have the following prerequisites set up:

- AWS CLI installed and configured with an appropriate profile.
- Terraform CLI installed on your machine.

Make sure to configure your AWS credentials using the AWS CLI or set up the necessary environment variables. If using a profile, ensure it is correctly configured in your AWS credentials file, typically located at `~/.aws/credentials`.

## AWS Provider Configuration

The Terraform code is configured to use a specific AWS profile to manage authentication. This allows you to keep your AWS access organized and secure. To use the profile with Terraform, you can set it in your AWS provider configuration block or export it as an environment variable. Here is an example:

```hcl
provider "aws" {
  region  = "us-west-2"
  profile = "your-profile-name" # Replace with your AWS profile name
}
```

Alternatively, set the profile as an environment variable before running Terraform commands:

```bash
export AWS_PROFILE=your-profile-name # Replace with your AWS profile name
```

Ensure the profile has the necessary permissions to create and manage the AWS resources as defined in the Terraform configurations.

## Getting Started

### Setting up the GitHub User with Terraform

1. **Navigate to the Directory**:
    ```
    cd terraform/iam/environment/dev
    ```

2. **Initialize Terraform**:
    ```bash
    terraform init
    ```

3. **Plan Your Terraform Changes**:
    ```bash
    terraform plan
    ```

4. **Apply Your Terraform Changes**:
    ```bash
    terraform apply
    ```

5. **Retrieve the Access Key for GitHub Actions**:
    ```bash
    terraform output -raw github_actions_access_key
    ```
   Copy the displayed value and add it to your GitHub repository as a secret named `AWS_ACCESS_KEY_ID`.

6. **Retrieve the Secret Key for GitHub Actions**:
    ```bash
    terraform output -raw github_actions_secret_key
    ```
   Copy the displayed value and add it to your GitHub repository as a secret named `AWS_SECRET_ACCESS_KEY`.

> **Note**: These credentials are crucial for the GitHub Actions workflow, enabling the push of the Docker image to ECR and triggering the ECS task deployment.

### Setting up VPC, ECR, and ECS with Terraform

1. **Navigate to the Directory**:
    ```bash
    cd terraform/compute/environment/dev
    ```

2. **Initialize Terraform**:
    ```bash
    terraform init
    ```

3. **Plan Your Terraform Changes**:
    ```bash
    terraform plan
    ```

4. **Apply Your Terraform Changes**:
    ```bash
    terraform apply
    ```

5. **Retrieve the Outputs**:

    - **ECR Image URI**: 
        ```bash
        terraform output ecr_image_uri
        ```
      Use this value for the `image` in `.aws/task-definition.json`.

    - **Task IAM Role ARN**: 
        ```bash
        terraform output task_iam_role_arn
        ```
      Use this ARN for the `taskRoleArn` in `.aws/task-definition.json`.

    - **Task Execution IAM Role ARN**: 
        ```bash
        terraform output task_exec_iam_role_arn
        ```
      Use this ARN for the `executionRoleArn` in `.aws/task-definition.json`.

    - **ALB DNS Name**: 
        ```bash
        terraform output alb_dns_name
        ```
      Use the resulting value as the URL to view the assessment result in your browser.

## Deployment

The application deployment leverages GitHub Actions, streamlining the processes of:

- Building a Docker image of the application.
- Pushing the built image to AWS ECR.
- Deploying the image to AWS ECS.

> **Special Note**: While provisioning with Terraform, a placeholder task definition is used. The actual task definition, which holds specifics about the application and its environment, gets deployed directly through the GitHub Actions workflow.

## Application Details

- **Type**: Simple Node.js application.
- **APIs**:
  - `GET /` - Health check endpoint, returns a 200 response.
  - `GET /index` - Delivers a sample HTML page.
- **Port**: The application listens on port `3000`.

## Infrastructure Details

- AWS ECS hosts a singular service and task, fitting for the application's simplicity. This task, responsible for running the container, boasts an auto-scaling feature, allowing it to scale anywhere between 2 and 100 tasks, depending on demand.
  
- To build a cost optimised deployment, Fargate spot instances have been employed, translating to potential cost savings of up to 70%.

- An application load balancer is used which will automatically perform health checks on the tasks deployed and only route traffic to the healthy ones.

- Multi AZ deployment is performed to ensure the application is highly available even if one AZ goes down.

## Future enhancement possibilities

- Some of the data(ex: cpu) is static within terraform code. They can be used as variables.

- Terraform code is divided into 4 stages: Compute, IAM, Networking and Storage. Networking and Storage aren't used at this stage. But This level of seperation gives code maintainability and reusability.

- Only dev environment is setup. We can use workspaces aswell. But we can also use seperate project files within the environment for staging and prod environments.

- The code is auto deployed when it is pushed to main branch. Pipelines can be setup for dev and staging branches as well.

- Monitoring and logging is also very important to ensure an application is highly available.