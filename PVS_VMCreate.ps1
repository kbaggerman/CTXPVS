
# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com
# Created on March 5, 2019


# Setting parameters for the connection
[CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = "None") ]
 
Param(
    # Citrix PVS Server IP
    [Parameter(Mandatory = $true)]
    [Alias('PVS Server IP')] [string] $ctxIP,
    # Nutanix cluster IP address
    [Parameter(Mandatory = $true)]
    [Alias('IP')] [string] $nxIP,   
    # Nutanix cluster username
    [Parameter(Mandatory = $true)]
    [Alias('User')] [string] $nxUser,
    # Nutanix cluster password
    [Parameter(Mandatory = $true)]
    [Alias('Password')] [System.Security.SecureString] $nxPassword
)
 
 Function write-log {
    <#
       .Synopsis
       Write logs for debugging purposes
       
       .Description
       This function writes logs based on the message including a time stamp for debugging purposes.
    #>
  param (
  $message,
  $sev = "INFO"
  )
  if ($sev -eq "INFO"){
    write-host "$(get-date -format "hh:mm:ss") | INFO | $message"
  } elseif ($sev -eq "WARN"){
    write-host "$(get-date -format "hh:mm:ss") | WARN | $message"
  } elseif ($sev -eq "ERROR"){
    write-host "$(get-date -format "hh:mm:ss") | ERROR | $message"
  } elseif ($sev -eq "CHAPTER"){
    write-host "`n`n### $message`n`n"
  }
} 


# Adding PS cmdlets for Nutanix
$loadedsnapins=(Get-PSSnapin -Registered | Select-Object name).name
if(!($loadedsnapins.Contains("NutanixCmdletsPSSnapin"))){
   Add-PSSnapin -Name NutanixCmdletsPSSnapin 
}

if ($null -eq (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue))
{
    write-log -message "Nutanix CMDlets are not loaded, aborting the script"
    break
}

# Adding PS cmdlets for Citrix PVS
$loadedsnapins=(Get-PSSnapin -Registered | Select-Object name).name
if(!($loadedsnapins.Contains("McliPSSnapIn"))){
   Add-PSSnapin -Name Citrix.PVS.Snapin 
}

if ($null -eq (Get-PSSnapin -Name Citrix.PVS.Snapin -ErrorAction SilentlyContinue))
{
    write-log -message "Citrix PVS cmdlets are not loaded, aborting the script"
    break
}

 
# Connecting to the Nutanix Cluster
$nxServerObj = Connect-NTNXCluster -Server $nxIP -UserName $nxUser -Password $nxPassword -AcceptInvalidSSLCerts

if ($null -eq (get-ntnxclusterinfo))
{
    write-log -message "Cluster connection isn't available, abborting the script"
    break
}

# Both the PVS cmdlets as the Nutanix cmdlets have to be installed

# Add-PSSnapin -Name McliPSSnapIn
# Add-PSSnapin -Name NutanixCmdletsPSSnapin

# Connecting to the Nutanix AHV Cluster and the Citrix PVS server

# Connect-NTNXCluster 10.68.68.40 -AcceptInvalidSSLCerts
Mcli-Run SetupConnection -p server=$ctxIP, port=54321
 
# Create VMs in AHV

 
 ##########################
 ## Get inputs & Defaults
 ##########################
 
 # Get vms array once
 #$vmid = Get-NTNXVM
 $vms = Get-NTNXVM
 
 # Create array for clone tasks
 $cloneTasks = @()

 # Get available images
 if ($vmid.vmName -contains $image.vmName) {
 Write-Host "$($vmid.vmName)"
 }
 else {
 Write-Host "No Images found!"
 Write-Host "Please provide a VM name"
 #break
 }

 # Select Image
 if ([string]::IsNullOrEmpty($image)) {
 $image = Read-Host "Please enter an image name "
 } 

 # Get VM prefix if not passed
 if ([string]::IsNullOrEmpty($prefix)) {
 $prefix = Read-Host "Please enter a name prefix and int structure [e.g. myClones-###] "
 }
 
 # Get starting int if not passed
 if ([string]::IsNullOrEmpty($startInt)) {
 $startInt = Read-Host "Please enter a starting int [e.g. 1] "
 }
 
 # If ints aren't formatted
 if ($prefix -notmatch '#') {
 $length = 3
 } else {
 $length = [regex]::matches($prefix,"#").count
 
 # Remove # from prefix
 $prefix = $prefix.Trim('#')
 }
 
 # Get VM quantity if not passed
 if ([string]::IsNullOrEmpty($quantity)) {
 $quantity = Read-Host "Please enter the desired quantity of VMs to be provisioned "
 }
 

 1..$quantity | %{
 
 $l_formattedInt = "{0:D$length}" -f $($_+$startInt-1)
 
 $l_formattedName = "$prefix$l_formattedInt"

 $lines = @($l_formattedName)
 
 
 
 # Create clone spec

 
 $spec = New-NTNXObject -Name VMCloneSpecDTO
 $spec.name = $l_formattedName

 foreach($vm in $vms) {
if($image -eq $vm.vmname) {
        $vmid = $vm.uuid} 
        }
 
 foreach ($p in $lines) {
 Clone-NTNXVirtualMachine -Vmid $vmid -SpecList $spec | Out-Null
 Write-Host "Creating clone $p" 
 }
}


# PARAMETERS

# hostname of one PVS Server

# $pvshost ="PVSServerHostname"

# Parameters which have to be edited according to environment - check for correct silo name

$description= "Description of the vDisk"
$OU="OU=computers,DC=contoso,DC=local"

# Parameters which have to be edited according to PVS Device Collection
$collection= "PVS Device Collection Name"
$site_1= "PVS Site 1"

# Get the VM Names, the MAC addresses and create targets in PVS

$vmid = get-ntnxvm
 
 foreach ($p in $vmid) {
 $mac = get-ntnxvmnic -vmid $p
 $p.vmName
 $mac.macAddress
 Mcli-Add Device -r deviceName=$($p.vmName), collectionName=Collection, siteName=Site, deviceMac=$($mac.macAddress)
}
