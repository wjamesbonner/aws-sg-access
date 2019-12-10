# Check for necessary module
if (Get-Module -ListAvailable -Name AWS.Tools.Common) {
    Import-Module AWS.Tools.Common
} 
else {
    Write-Host "Module Import-Module AWS.Tools.Common has not been installed.  Please run this libraries setup script."
    return;
}

# Check for necessary module
if (Get-Module -ListAvailable -Name AWS.Tools.ResourceGroups) {
    Import-Module AWS.Tools.ResourceGroups
} 
else {
    Write-Host "Module Import-Module AWS.Tools.ResourceGroups has not been installed.  Please run this libraries setup script."
    return;
}

# Check for necessary module
if (Get-Module -ListAvailable -Name AWS.Tools.EC2) {
    Import-Module AWS.Tools.EC2
} 
else {
    Write-Host "Module Import-Module AWS.Tools.EC2 has not been installed.  Please run this libraries setup script."
    return;
}

# Check for necessary module
if (Get-Module -ListAvailable -Name AWS.Tools.ECS) {
    Import-Module AWS.Tools.ECS
} 
else {
    Write-Host "Module Import-Module AWS.Tools.ECS has not been installed.  Please run this libraries setup script."
    return;
}

# Check for necessary module
if (Get-Module -ListAvailable -Name AWS.Tools.ECR) {
    Import-Module AWS.Tools.ECR
} 
else {
    Write-Host "Module Import-Module AWS.Tools.ECR has not been installed.  Please run this libraries setup script."
    return;
}

# Check for necessary module
if (Get-Module -ListAvailable -Name AWS.Tools.RDS) {
    Import-Module AWS.Tools.RDS
} 
else {
    Write-Host "Module Import-Module AWS.Tools.RDS has not been installed.  Please run this libraries setup script."
    return;
}

# Check for necessary module
if (Get-Module -ListAvailable -Name AWS.Tools.S3) {
    Import-Module AWS.Tools.S3
} 
else {
    Write-Host "Module Import-Module AWS.Tools.S3 has not been installed.  Please run this libraries setup script."
    return;
}

# Check for necessary module
if (Get-Module -ListAvailable -Name AWS.Tools.ElasticFileSystem) {
    Import-Module AWS.Tools.ElasticFileSystem
} 
else {
    Write-Host "Module Import-Module AWS.Tools.ElasticFileSystem has not been installed.  Please run this libraries setup script."
    return;
}