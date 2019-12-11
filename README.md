# aws-sg-access
Gives a developer temporary access to AWS resources by adding temporary allow rules to security groups.

## Setup
1. Install the AWS Tools for PowerShell from https://aws.amazon.com/powershell/.

2. Clone this repository to a local source repo.

3. Run the setup script to make sure all necessary AWS module dependencies are installed.

4. Create a lambda function using Python 3.8 using the PurgeExpiredSgRules.lambda code, and schedule the function to execute hourly using CloudWatch rules.

## Use
1. Execute the desired script to gain the necessary temporary firewall access.  e.g. .\aws_grant_mssql.ps1 -serviceId *******
    
