param(
    [Alias("s")]
    [string] $serviceFamily = "database-hosting",

    [Alias("t")]
    [string] $tagName = "service-family",

    [Alias("i")]
    [string] $serviceId  = "",

    [Alias("ti")]
    [string] $tagNameId = "service-id",

    [Alias("d")]
    [switch] $debug = $false,

    [Alias("h")]
    [switch] $help = $false
)

if ($help) {
	Write-Output "`t aws_create_vpc.ps1 will configure an existing ECS cluster tagged as part of the service family to run a new instance of the service, or create a new cluster if none exist already"
	Write-Output "`t Prerequisites: Powershell"
	Write-Output "`t "
	Write-Output "`t Parameters:"
	Write-Output "`t "
	Write-Output "`t serviceFamily"
	Write-Output "`t     The name of the service family."
	Write-Output ("`t     Default: {0}" -f $serviceFamily)
    Write-Output "`t     Alias: s"
	Write-Output "`t     Example: ./aws_grant_mssql.ps1 -serviceFamily database-hosting"
    Write-Output "`t     Example: ./aws_grant_mssql.ps1 -s database-hosting"
	
    Write-Output "`t "
	Write-Output "`t tagName"
	Write-Output "`t     The name of the tag that stores the service family name"
	Write-Output ("`t     Default: {0}" -f $tagName)
    Write-Output "`t     Alias: t"
	Write-Output "`t     Example: ./aws_grant_mssql.ps1 -tagName service-family"
    Write-Output "`t     Example: ./aws_grant_mssql.ps1 -t service-family"

    Write-Output "`t "
	Write-Output "`t serviceId"
	Write-Output "`t     The name of the tag that stores the service family name"
	Write-Output ("`t     Default: {0}" -f $serviceId)
    Write-Output "`t     Alias: i"
	Write-Output "`t     Example: ./aws_grant_mssql.ps1 -serviceId s1234567"
    Write-Output "`t     Example: ./aws_grant_mssql.ps1 -i s1234567"

    Write-Output "`t "
	Write-Output "`t tagNameId"
	Write-Output "`t     The name of the tag that stores the service id"
	Write-Output ("`t     Default: {0}" -f $tagNameId)
    Write-Output "`t     Alias: ti"
	Write-Output "`t     Example: ./aws_grant_mssql.ps1 -tagNameId service-id"
    Write-Output "`t     Example: ./aws_grant_mssql.ps1 -ti service-id"

    Write-Output "`t "
	Write-Output "`t debug"
	Write-Output "`t     If set, a transcript of the session will be recorded."
	Write-Output ("`t     Default: {0}" -f $debug)
    Write-Output "`t     Alias: ti"
	Write-Output "`t     Example: ./aws_grant_mssql.ps1 -tagNameId service-id"
    Write-Output "`t     Example: ./aws_grant_mssql.ps1 -ti service-id"

    return
}

# Prompt for name if not specified
if ($serviceFamily -eq "") {
	$serviceFamily = Read-Host "Enter the name of the service family"
}
$serviceFamily = $serviceFamily.ToLower()

# Prompt for name if not specified
if ($tagName -eq "") {
	$tagName = Read-Host "Enter the name of the tag that contains the service family in your environment"
}
$tagName = $tagName.ToLower()

# Prompt for name if not specified
if ($serviceId -eq "") {
	$serviceId = Read-Host "Enter the value of the service id"
}
$serviceId = $serviceId.ToLower()

# Prompt for name if not specified
if ($tagNameId -eq "") {
	$tagNameId = Read-Host "Enter the name of the tag that contains the service id in your environment"
}
$tagNameId = $tagNameId.ToLower()

# navigate to library root
cd $PSScriptRoot

if($debug) {
    $DebugPreference = "Continue"
    $transcriptName = ("aws_cgrant_mssql-{0}.txt" -f [DateTimeOffset]::Now.ToUnixTimeSeconds())
    Start-Transcript -Path $transcriptName

    $serviceFamily
    $tagName
    $serviceId
    $tagNameId
}

# load necessary modules
.\aws_load_default_modules.ps1

Write-Debug "`t Building environment tags..."
$hash = @{Key="Name"; Value=$serviceFamily}
$nameTag = [PSCustomObject]$hash
Write-Debug $nameTag

$hash = @{Key=$tagName; Value=$serviceFamily}
$serviceTag = [PSCustomObject]$hash
Write-Debug $serviceTag

$hash = @{Key=$tagNameId; Value=$serviceId}
$serviceIdTag = [PSCustomObject]$hash
Write-Debug $serviceIdTag

$hash = @{Key="management-mode"; Value="automatic"}
$managementTag = [PSCustomObject]$hash
Write-Debug $managementTag

$hash = @{Key="management-task"; Value="delete"}
$managementTask = [PSCustomObject]$hash
Write-Debug $managementTask

$hash = @{Key="management-task-data"; Value=("{0}" -f [DateTimeOffset]::Now.AddHours(12).ToUnixTimeSeconds())}
$managementData = [PSCustomObject]$hash
Write-Debug $managementData

Write-Debug "`t Building tag filters and retrieving tags..."
$filters = @()
$filter = New-Object -TypeName Amazon.EC2.Model.Filter
$filter.Name = "resource-type"
$filter.Values.Add("security-group")
$filters += $filter

$filter = New-Object -TypeName Amazon.EC2.Model.Filter
$filter.Name = "tag:root"
$filter.Values.Add("true")
$filters += $filter
$securityGroupTags = Get-EC2Tag -Filter $filters

$filter = New-Object -TypeName Amazon.EC2.Model.Filter
$filter.Name = ("tag:{0}" -f $tagName)
$filter.Values.Add($serviceFamily)
$serviceFamilyTags = Get-EC2Tag -Filter $filter

$filter = New-Object -TypeName Amazon.EC2.Model.Filter
$filter.Name = ("tag:{0}" -f $tagNameId)
$filter.Values.Add($serviceId)
$serviceIdTags = Get-EC2Tag -Filter $filter

if($securityGroupTags -eq $null -or $serviceFamilyTags -eq $null -or $serviceIdTags -eq $null) {
    Write-Debug "`t No security group matches all necessary criteria."
    Stop-Transcript
    return
}

Write-Debug "`t Verifying resource ID's match across all filters..."
if($securityGroupTags.ResourceId -eq $serviceFamilyTags.ResourceId -and $securityGroupTags.ResourceId -eq $serviceIdTags.ResourceId) {
    $parentSg = Get-EC2SecurityGroup -GroupId $securityGroupTags.ResourceId
}

if($parentSg -eq $null) {
    Write-Debug "`t Mismatch of sg ID's across tag searches"
    Stop-Transcript
    return
}

Write-Debug "`t Creating and configuring new security group..."
$sg = New-EC2SecurityGroup -GroupName ("{0}-{1}" -f $serviceFamily,[DateTimeOffset]::Now.ToUnixTimeSeconds()) -Description ("{0}-{1}" -f $serviceFamily,[DateTimeOffset]::Now.ToUnixTimeSeconds()) -VpcId $parentSg.VpcId
$publicIp = (Invoke-WebRequest -Uri "api.ipify.org").Content

Write-Debug "`t Defining IP ranges and default egress rules..."
$defaultIpRange = New-Object -TypeName Amazon.EC2.Model.IpRange
$defaultIpRange.CidrIp = "0.0.0.0/0"
#$defaultIpRange.Description = $null   # Do not set description or it will not match default egress rule.  
                                # Powershell differentiates null and parameter not set. 
                                # https://stackoverflow.com/questions/28697349/how-do-i-assign-a-null-value-to-a-variable-in-powershell
Write-Debug $defaultIpRange

$thisPcIpRange = New-Object -TypeName Amazon.EC2.Model.IpRange
$thisPcIpRange.CidrIp = ("{0}/32" -f $publicIp)
$thisPcIpRange.Description = ("automatic-{0}" -f [DateTimeOffset]::Now.ToUnixTimeSeconds())
Write-Debug $thisPcIpRange

$outPermission = New-Object -TypeName Amazon.EC2.Model.IpPermission
$outPermission.FromPort = 0
$outPermission.IpProtocol = "-1"
$outPermission.Ipv4Ranges = $defaultIpRange
$outPermission.ToPort = 0
Write-Debug $outPermission

Write-Debug "`t Building security group ingress rules..."
$mssqlPermission = New-Object -TypeName Amazon.EC2.Model.IpPermission
$mssqlPermission.FromPort = 1433
$mssqlPermission.IpProtocol = "tcp"
$mssqlPermission.Ipv4Ranges = $thisPcIpRange
$mssqlPermission.ToPort = 1433
Write-Debug $mssqlPermission

Write-Debug "`t Applying ingress rules..."
Grant-EC2SecurityGroupIngress -GroupId $sg -IpPermission $mssqlPermission

Write-Debug "`t Revoking default egress rules..."
Revoke-EC2SecurityGroupEgress -GroupId $sg -IpPermission $outPermission

Write-Debug "`t Building inter-security group rules..."
$groupPermissions = New-Object -TypeName Amazon.EC2.Model.UserIdGroupPair
$groupPermissions.GroupId = $sg #Permission from this group
$groupPermissions.UserId = $parentSg.GroupId #Permission to this group
$groupPermissions.Description = ("automatic-{0}" -f [DateTimeOffset]::Now.ToUnixTimeSeconds())
Write-Debug $groupPermissions

$sgPermission = New-Object -TypeName Amazon.EC2.Model.IpPermission
$sgPermission.FromPort = 1433
$sgPermission.IpProtocol = "tcp"
$sgPermission.ToPort = 1433
$sgPermission.UserIdGroupPairs = $groupPermissions
Write-Debug $sgPermission

Write-Debug "`t Allowing access to service ports..."
Grant-EC2SecurityGroupIngress -GroupId $parentSg.GroupId -IpPermission $sgPermission

Write-Debug "`t Tagging security group..."
New-EC2Tag -Resource $sg -Tag $nameTag
New-EC2Tag -Resource $sg -Tag $serviceTag
New-EC2Tag -Resource $sg -Tag $serviceIdTag
New-EC2Tag -Resource $sg -Tag $managementTag
New-EC2Tag -Resource $sg -Tag $managementTask
New-EC2Tag -Resource $sg -Tag $managementData

if($debug) {
    Stop-Transcript
    $DebugPreference = "SilentlyContinue"
}