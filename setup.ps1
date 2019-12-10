#Requires -RunAsAdministrator
param(
    [Alias("f")]
    [switch] $force = $false,

    [Alias("h")]
    [switch] $help = $false
)

if ($help) {
	Write-Host "Setup is a script that performs the one time operations needed to use this library.  It should also be run on update of the library."
	Write-Host "Prerequisites: Powershell"
	Write-Host ""
	Write-Host "Parameters:"
	Write-Host ""
	Write-Host "force"
	Write-Host "    Force the reinstallation and upgrade of modules."
	Write-Host "    Default: true"
    Write-Host "    Alias: f"
	Write-Host "    Example: ./setup.ps1 -force"
    Write-Host "    Example: ./setup.ps1 -f"
	return
}

if((Get-PSRepository -Name "PSGallery").InstallationPolicy -ne "Trusted") {
    Write-Host "Setting PSGallery to trusted."
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
}

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if(!($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Write-Host "Please re-run as administrator."
    return
}

# Track whether any modules are installed
$changesMade = $false

# Update modules and cleanup old versions to minimize warnings during installation of any missing modules.
Update-AWSToolsModule -CleanUp -AllowClobber -Force -Confirm

# Check for modules required by this library
if (!(Get-Module -ListAvailable -Name AWS.Tools.Installer) -or $force) {
    if($force) {
        Install-Module -Name AWS.Tools.Installer -AllowClobber -Force -Confirm
    } else {
        Install-Module -Name AWS.Tools.Installer
    }

    $changesMade = $true
}

# Check for modules required by this library
if (!(Get-Module -ListAvailable -Name AWS.Tools.Common) -or $force) {
    if($force) {
        Install-Module -Name AWS.Tools.Common -AllowClobber -Force -Confirm
    } else {
        Install-Module -Name AWS.Tools.Common
    }

    $changesMade = $true
}

# Check for modules required by this library
if (!(Get-Module -ListAvailable -Name AWS.Tools.ResourceGroups) -or $force) {
    if($force) {
        Install-Module -Name AWS.Tools.ResourceGroups -AllowClobber -Force -Confirm
    } else {
        Install-Module -Name AWS.Tools.ResourceGroups
    }

    $changesMade = $true
}

# Check for modules required by this library
if (!(Get-Module -ListAvailable -Name AWS.Tools.EC2) -or $force) {
    if($force) {
        Install-Module -Name AWS.Tools.EC2 -AllowClobber -Force -Confirm
    } else {
        Install-Module -Name AWS.Tools.EC2
    }

    $changesMade = $true
}

# Check for modules required by this library
if (!(Get-Module -ListAvailable -Name AWS.Tools.ECS) -or $force) {
    if($force) {
        Install-Module -Name AWS.Tools.ECS -AllowClobber -Force -Confirm
    } else {
        Install-Module -Name AWS.Tools.ECS
    }

    $changesMade = $true
}

# Check for modules required by this library
if (!(Get-Module -ListAvailable -Name AWS.Tools.ECR) -or $force) {
    if($force) {
        Install-Module -Name AWS.Tools.ECR -AllowClobber -Force -Confirm
    } else {
        Install-Module -Name AWS.Tools.ECR
    }

    $changesMade = $true
}

# Check for modules required by this library
if (!(Get-Module -ListAvailable -Name AWS.Tools.RDS) -or $force) {
    if($force) {
        Install-Module -Name AWS.Tools.RDS -AllowClobber -Force -Confirm
    } else {
        Install-Module -Name AWS.Tools.RDS
    }

    $changesMade = $true
}

# Check for modules required by this library
if (!(Get-Module -ListAvailable -Name AWS.Tools.S3) -or $force) {
    if($force) {
        Install-Module -Name AWS.Tools.S3 -AllowClobber -Force -Confirm
    } else {
        Install-Module -Name AWS.Tools.S3
    }

    $changesMade = $true
}

# Check for modules required by this library
if (!(Get-Module -ListAvailable -Name AWS.Tools.ElasticFileSystem) -or $force) {
    if($force) {
        Install-Module -Name AWS.Tools.ElasticFileSystem -AllowClobber -Force -Confirm
    } else {
        Install-Module -Name AWS.Tools.ElasticFileSystem
    }

    $changesMade = $true
}

# Check for modules required by this library
if (!(Get-Module -ListAvailable -Name AWS.Tools.ElasticLoadBalancingV2) -or $force) {
    if($force) {
        Install-Module -Name AWS.Tools.ElasticLoadBalancingV2 -AllowClobber -Force -Confirm
    } else {
        Install-Module -Name AWS.Tools.ElasticLoadBalancingV2
    }

    $changesMade = $true
}

if($changesMade) {
    Write-Host "Modules successfully installed and updated."
}else {
    Write-Host "Existing modules updated, no missing modules detected."
}