#!/usr/bin/env pwsh

# Set OutputRendering for colorized output
$PSStyle.OutputRendering = 'Ansi'

# Generate 6 random bytes
$bytes = New-Object Byte[] 6
(New-Object Security.Cryptography.RNGCryptoServiceProvider).GetBytes($bytes)

# Convert the bytes to base64
$randomBase64Chars = [Convert]::ToBase64String($bytes)

# Remove any non-alphanumeric characters from the base64 string
$randomBase64Chars = $randomBase64Chars -replace '[^a-zA-Z0-9]',''

function Set-FirewallRule {
  param(
    [Parameter(Mandatory = $true)] [string]$DisplayName,
    [Parameter(Mandatory = $true)] [int]$StartPort,
    [Parameter(Mandatory = $true)] [int]$EndPort,
    [Parameter(Mandatory = $false)] [string]$Action = 'Allow',
    [Parameter(Mandatory = $false)] [string]$Protocol = 'TCP'
  )

  if ($StartPort -gt $EndPort) {
    Write-Host "StartPort should not be greater than EndPort." -ForegroundColor Red
    return
  }

  $rule = Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue

  if ($null -eq $rule) {
    New-NetFirewallRule -DisplayName $DisplayName -Direction Inbound -Action $Action -Protocol $Protocol -LocalPort ($StartPort..$EndPort)
  }
  else {
    Write-Host "Firewall rule $DisplayName already exists, skipping creation." -ForegroundColor Yellow
  }
}


$currentWd = Get-Location
$Env:Cwd = $currentWd

# Form the VM name
$osName = "ubuntu"
$osVersion = "22.04.2"
$osType = "live-server-amd64"
$vmName = "${osName}${osVersion}base-${randomBase64Chars}"
$packerTemplateName = "packer.pkr.hcl"
$packerTemplatePath = Resolve-Path "${currentWd}\${packerTemplateName}"
$vagrantFileName = "Vagrantfile"
$vagrantFilePath = Resolve-Path "${currentWd}\${vagrantFileName}"
$vagrantBoxName = "${osName}${osVersion}.box"
$Env:VM_NAME = $vmName
$Env:VAGRANT_BOX_NAME = "${vagrantBoxName}"
$Env:OS_VERSION = $osVersion
$osBaseUrl = "https://releases.${osName}.com"
$osUrl = "${osBaseUrl}/${osVersion}/${osName}-${osVersion}-${osType}.iso"

$checksumsUrl = "${osBaseUrl}/${osVersion}/SHA256SUMS"
$checksumsContent = Invoke-RestMethod -Uri $checksumsUrl
$checksumLine = $checksumsContent -split "`n" | Where-Object { $_ -like "*${osType}.iso" }
$checksum = $checksumLine -split " " | Select-Object -First 1
Write-Host "OS Checksum is: $checksum" -ForegroundColor Yellow

$osChecksum = $checksum
$Env:OS_CHECKSUM = $osChecksum

# Check if osChecksum is null and exit if true
if ($null -eq $osChecksum) {
  Write-Host "OS Checksum is null, exiting script..." -ForegroundColor Red
  exit 1
}

Write-Host "You will likely need administrator or very high permissions to run this script" -ForegroundColor Yellow

try {
  $opensslVersion = & openssl version
  Write-Host "OpenSSL is installed: $opensslVersion" -ForegroundColor Green
} catch {
  Write-Host "OpenSSL is not installed or not found in PATH" -ForegroundColor Red
  exit 1
}

$password = "vagrant"
$hashedPassword = Write-Output $password | openssl passwd -6 -stdin


# Create or confirm existence of firewall rules for these port ranges
Set-FirewallRule -DisplayName "Open Port 8000-9000" -startPort 8000 -endPort 9000

# Create or confirm existence of firewall rule for TCP port 3389
Set-FirewallRule -DisplayName "Open Port 3389" -startPort 3389 -endPort 3389

# Create or confirm existence of firewall rule for TCP port 22
Set-FirewallRule -DisplayName "Open Port 22" -startPort 22 -endPort 22

# Define the virtual switch
$VirtualSwitch = "Wi-Fi"
$Env:NETWORK_ADAPTER = $VirtualSwitch

$IF_ALIAS = (Get-NetAdapter -Name "vEthernet ($VirtualSwitch)").ifAlias

$firewallRule = Get-NetFirewallRule -DisplayName "Allow incoming from $VirtualSwitch" -ErrorAction SilentlyContinue

if ($null -eq $firewallRule) {
  # If the firewall rule doesn't exist, create it
  New-NetFirewallRule -DisplayName "Allow incoming from $VirtualSwitch" -Direction Inbound -InterfaceAlias $IF_ALIAS -Action Allow
  Set-NetConnectionProfile -InterfaceAlias $IF_ALIAS -NetworkCategory Private
  Write-Host "Created firewall rule for virtual switch $VirtualSwitch" -ForegroundColor Green
} else {
  # If the firewall rule already exists, skip it
  Write-Host "Firewall rule for virtual switch $VirtualSwitch exists" -ForegroundColor Yellow
}

# Define a cleanup function
function Cleanup {
  # Clean up VM if it exists
  Remove-VMIfExists -VMName $vmName
}
# Run Packer and clean up if a terminating error occurs
try {
  if (Test-Path "${packerTemplatePath}") {
    packer build -var "vm_name=$vmName" -var "hashed_password=$hashedPassword" -var "network_adapter=$VirtualSwitch" -var "os_url=$osUrl" -var "os_type=$osType" -var "os_version=$osVersion" -var "os_checksum=$osChecksum" -var "vagrant_box_name=$vagrantBoxName" $packerTemplatePath
  }
  else {
    Write-Host "Packer file cannot be found at ${packerTemplatePath}" -ForegroundColor Red
  }
} catch {
  Write-Host "Error occured with 'packer build', attempting cleanup $vmName" -ForegroundColor Red
  Cleanup
  throw $_
}

# If Packer failed, clean up the VM
if ($LASTEXITCODE -ne 0) {
  Cleanup
} else {
  # Get SHA256 checksum of the box file and save it in a .SHA256sum file
  Get-FileHash -Path "${currentWd}/${vagrantBoxName}" -Algorithm SHA256 |
  ForEach-Object { "{0} {1}" -f $_.Hash,(Split-Path $_.Path -Leaf) } |
  Out-File -FilePath "${currentWd}/${vagrantBoxName}.SHA256sum"

  vagrant box add --name $vmName --force "${currentWd}/${vagrantBoxName}"
  if (Test-Path "${vagrantFilePath}") {
    try {
      # Run vagrant up
      vagrant up
      if ($?) {
        # If vagrant up was successful, run the Set-VM command
        Set-VM -VMName $vmName -EnhancedSessionTransportType HvSocket
        Write-Host "Successfully executed 'vagrant up' and 'Set-VM' commands" -ForegroundColor Green
      } else {
        throw "Vagrant up failed."
      }
    } catch {
      Write-Host "Error encountered during 'vagrant up'. Executing halt and destroy commands" -ForegroundColor Red
      # If vagrant up failed, run vagrant halt -f ; vagrant destroy -f
      vagrant halt -f
      vagrant destroy -f
    }
  }
  else {
    Write-Host "Vagrant file cannot be found at ${vagrantFilePath}" -ForegroundColor Red
  }
}
