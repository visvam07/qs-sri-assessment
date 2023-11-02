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
      Reference this value as the `image` in `.aws/task-definition.json`.

    - **Task IAM Role ARN**: 
        ```bash
        terraform output task_iam_role_arn
        ```
      Use this ARN for the `taskRoleArn` in `.aws/task-definition.json`.

    - **Task Execution IAM Role ARN**: 
        ```bash
        terraform output task_exec_iam_role_arn
        ```
      Reference this ARN for the `executionRoleArn` in `.aws/task-definition.json`.

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
  
- Cost efficiency is paramount. As such, Fargate spot instances have been employed, translating to potential cost savings of up to 70%.