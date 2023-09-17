# RealWorld Terraform AWS Project

This repository contains a script and Terraform configurations to set up a RealWorld application infrastructure on AWS.

Prerequisites:
1. An AWS account.
2. Bash terminal or similar for executing scripts (Linux/Mac).

Description:
This project automates the setup of the RealWorld application on AWS using Terraform. It will create a VPC, EC2 instances, Load Balancers, Security Groups, and Route53 configurations.

Installation & Usage:
1. Clone the repository: git clone https://github.com/Ayo1009/RealWorldApp.git, cd RealWorldApp

2. Configure AWS CLI: Before running the script, make sure to configure your AWS CLI with the necessary credentials. If you haven't done so, run: aws configure

3. Run the script: chmod +x manage_terraform.sh,  ./manage_terraform.sh

The script will:

Check for Terraform and AWS CLI installations.
Install them if missing.
Provide a menu for Terraform operations.

4. Choose a Terraform operation:

After running the script, choose one of the available Terraform operations:

Initialize
Validate
Plan
Apply changes
Destroy infrastructure
For example, to deploy the infrastructure to AWS, select 4. Apply changes.

Important Notes:
1. The script and Terraform configurations are set up with default values. Adjust the configurations in the Terraform files if you need custom settings for your AWS infrastructure.
2. Ensure that your AWS account isn't blocked and doesn't have billing issues to avoid any disruptions during the setup.
3. Costs may be incurred on AWS depending on the resources created.
