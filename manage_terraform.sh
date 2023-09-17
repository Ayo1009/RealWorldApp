#!/bin/bash

# Check if Terraform is installed
terraform_check() {
    if ! command -v terraform &> /dev/null; then
        echo "Terraform not found! Installing..."
        wget https://releases.hashicorp.com/terraform/1.0.7/terraform_1.0.7_linux_amd64.zip
        unzip terraform_1.0.7_linux_amd64.zip
        sudo mv terraform /usr/local/bin/
        rm terraform_1.0.7_linux_amd64.zip
    else
        echo "Terraform is already installed!"
    fi
}

# Check if AWS CLI is installed
awscli_check() {
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI not found! Installing..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -r aws awscliv2.zip
    else
        echo "AWS CLI is already installed!"
    fi
}

manage_terraform() {
    echo "1. Initialize"
    echo "2. Validate"
    echo "3. Apply changes"
    echo "4. Destroy infrastructure"
    read -p "Choose an option: " choice

    case $choice in
        1)
            terraform init
            ;;
        2)
            terraform validate
            ;;
        3)
            terraform apply
            ;;
        4)
            terraform destroy
            ;;
        *)
            echo "Invalid option!"
            ;;
    esac
}

terraform_check
awscli_check
manage_terraform
