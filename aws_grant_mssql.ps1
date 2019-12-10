param(
    [Alias("sf")]
    [string] $serviceFamily = "database-hosting",

    [Alias("t")]
    [string] $tagName = "service-family",

    [Alias("si")]
    [string] $serviceId  = "",

    [Alias("ti")]
    [string] $tagNameId = "service-id",

    [Alias("ip")]
    [string] $ipAddress = "",

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
    Write-Output "`t     Alias: sf"
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
    Write-Output "`t     Alias: si"
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
	Write-Output "`t ipAddress"
	Write-Output "`t     The IP address to allow"
	Write-Output ("`t     Default: {0}" -f $ipAddress)
    Write-Output "`t     Alias: ip"
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

# Check for public IP
if ($ipAddress -eq "") {
	$publicIp = (Invoke-WebRequest -Uri "api.ipify.org").Content
}

# navigate to library root
cd $PSScriptRoot

if($debug) {
    $DebugPreference = "Continue"
    $transcriptName = ("aws_grant_mssql-{0}.txt" -f [DateTimeOffset]::Now.ToUnixTimeSeconds())
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
    if($debug){Stop-Transcript}
    return
}

Write-Debug "`t Verifying resource ID's match across all filters..."
if($serviceFamilyTags.ResourceId.Contains($securityGroupTags.ResourceId) -and $serviceIdTags.ResourceId.Contains($securityGroupTags.ResourceId)) {
    $sg = (Get-EC2SecurityGroup -GroupId $securityGroupTags.ResourceId)
}

if($sg -eq $null) {
    Write-Debug "`t Mismatch of sg ID's across tag searches"
    if($debug){Stop-Transcript}
    return
}

Write-Debug "`t Configuring security group..."


Write-Debug "`t Creating management-task instructions..."
$managementTaskHash = @{"management-task"="delete"; data=("{0}" -f [DateTimeOffset]::Now.AddHours(12).ToUnixTimeSeconds())}
$managementTask = [PSCustomObject]$managementTaskHash
$managementTask = ($managementTask | ConvertTo-Json -Depth 5 -Compress)

$thisPcIpRange = New-Object -TypeName Amazon.EC2.Model.IpRange
$thisPcIpRange.CidrIp = ("{0}/32" -f $publicIp)
$thisPcIpRange.Description = ("json={0}" -f [System.Web.HttpUtility]::HtmlEncode($managementTask))
Write-Debug $thisPcIpRange

Write-Debug "`t Building security group ingress rule..."
$mssqlPermission = New-Object -TypeName Amazon.EC2.Model.IpPermission
$mssqlPermission.FromPort = 1433
$mssqlPermission.IpProtocol = "tcp"
$mssqlPermission.Ipv4Ranges = $thisPcIpRange
$mssqlPermission.ToPort = 1433
Write-Debug $mssqlPermission

Write-Debug "`t Applying ingress rules..."
try{
    Grant-EC2SecurityGroupIngress -GroupId $sg.GroupId -IpPermission $mssqlPermission 
} catch {
    Write-Debug "`t Rule already exists."
}

if($debug) {
    Stop-Transcript
    $DebugPreference = "SilentlyContinue"
}