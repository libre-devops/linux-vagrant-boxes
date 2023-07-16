#!/usr/bin/env pwsh

# Set OutputRendering for colorized output
$PSStyle.OutputRendering = 'Ansi'

# Generate 6 random bytes
$bytes = New-Object Byte[] 6
(New-Object Security.Cryptography.RNGCryptoServiceProvider).GetBytes($bytes)

# Convert the bytes to base64
$randomBase64Chars = [Convert]::ToBase64String($bytes)

# Remove any non-alphanumeric characters from the base64 string
$randomBase64Chars = $randomBase64Chars -replace '[^a-zA-Z0-9]', ''

# Form the VM name
$osName = "ubuntu"
$osVersion = "22.04.2"
$osType = "desktop-amd64"
$vmName = "packer-${osName}${osVersion}base${randomBase64Chars}"
$Env:VM_NAME=$vmName
$Env:VAGRANT_BOX_NAME="${osName}${osVersion}.box"
$Env:OS_VERSION=$osVersion
$osBaseUrl = "https://releases.${osName}.com"
$osUrl = "${osBaseUrl}/${osVersion}/${osName}-${osVersion}-${osType}.iso"

$checksumsUrl = "${osBaseUrl}/${osVersion}/SHA256SUMS"
$checksumsContent = Invoke-RestMethod -Uri $checksumsUrl
$checksumLine = $checksumsContent -split "`n" | Where-Object { $_ -like "*${osType}.iso" }
$checksum = $checksumLine -split " " | Select-Object -First 1
Write-Host "OS Checksum is: $checksum" -ForegroundColor Yellow

$osChecksum = $checksum
$Env:OS_CHECKSUM=$osChecksum

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

# Define the start and end of the port range, vagrant by default uses 8000-9000
$startPort = 8000
$endPort = 9000

# Define the rule name
$ruleName = "Open Ports $startPort-$endPort"

# Check if a firewall rule for this port range already exists
$firewallRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

if ($null -eq $firewallRule) {
    # If the firewall rule doesn't exist, create it
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -LocalPort $startPort-$endPort -Protocol TCP -Action Allow
    Write-Host "Created firewall rule for ports $startPort-$endPort" -ForegroundColor Green
} else {
    # If the firewall rule already exists, skip it
    Write-Host "Firewall rule for ports $startPort-$endPort already exists" -ForegroundColor Yellow
}

# Define the start and end of the port range, vagrant by default uses 8000-9000
$startPort = 3389
$endPort = 3389

# Define the rule name
$ruleName = "Open Ports $startPort-$endPort"

# Check if a firewall rule for this port range already exists
$firewallRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

if ($null -eq $firewallRule) {
    # If the firewall rule doesn't exist, create it
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -LocalPort $startPort-$endPort -Protocol TCP -Action Allow
    Write-Host "Created firewall rule for ports $startPort-$endPort" -ForegroundColor Green
} else {
    # If the firewall rule already exists, skip it
    Write-Host "Firewall rule for ports $startPort-$endPort already exists" -ForegroundColor Yellow
}

# Define the start and end of the port range, vagrant by default uses 8000-9000
$startPort = 22
$endPort = 22

# Define the rule name
$ruleName = "Open Ports $startPort-$endPort"

# Check if a firewall rule for this port range already exists
$firewallRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

if ($null -eq $firewallRule) {
    # If the firewall rule doesn't exist, create it
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -LocalPort $startPort-$endPort -Protocol TCP -Action Allow
    Write-Host "Created firewall rule for ports $startPort-$endPort" -ForegroundColor Green
} else {
    # If the firewall rule already exists, skip it
    Write-Host "Firewall rule for ports $startPort-$endPort already exists" -ForegroundColor Yellow
}

# Define the virtual switch
$VirtualSwitch = "Wi-Fi"
$Env:NETWORK_ADAPTER=$VirtualSwitch

$IF_ALIAS = (Get-NetAdapter -Name "vEthernet ($VirtualSwitch)").ifAlias

$firewallRule = Get-NetFirewallRule -DisplayName "Allow incoming from $VirtualSwitch" -ErrorAction SilentlyContinue

if ($null -eq $firewallRule) {
    # If the firewall rule doesn't exist, create it
    New-NetFirewallRule -Displayname "Allow incoming from $VirtualSwitch" -Direction Inbound -InterfaceAlias $IF_ALIAS -Action Allow
    Set-NetConnectionProfile -InterfaceAlias $IF_ALIAS -NetworkCategory Private
    Write-Host "Created firewall rule for virtual switch $VirtualSwitch" -ForegroundColor Green
} else {
    # If the firewall rule already exists, skip it
    Write-Host "Firewall rule for virtual switch $VirtualSwitch exists" -ForegroundColor Yellow
}

# Define a cleanup function
function Cleanup {
    # Get the VM
    $vm = Get-VM -Name $vmName

    # If the VM exists, stop and delete it
    if ($vm) {
        # Stop the VM
        Stop-VM -Name $vm.Name -Force -Confirm:$false

        # Wait for the VM to stop
        while ((Get-VM -Name $vm.Name).State -ne 'Off') {
            Start-Sleep -Seconds 5
        }

        # Delete the VM
        Remove-VM -Name $vm.Name -Force -Confirm:$false
        Write-Host "Cleanup performed, deleted VM $vmName" -ForegroundColor Red
    }
    else {
        Write-Host "VM: $vmName cannot be found, Ignore any errors as this is intentional to force removal with this script" -ForegroundColor Green
    }
}

# Run Packer and clean up if a terminating error occurs
try {
    packer build -force -var "vm_name=$vmName" -var "hashed_password=$hashedPassword" -var "network_adapter=$VirtualSwitch" -var "os_url=$osUrl" -var "os_type=$osType" -var "os_version=$osVersion" -var "os_checksum=$osChecksum" .\packer.pkr.hcl
} catch {
    Write-Host "Error occured with 'packer build', attempting cleanup $vmName" -ForegroundColor Red
    Cleanup
    throw $_
}

# If Packer failed, clean up the VM
if ($LASTEXITCODE -ne 0) {
    Cleanup
} else {
    vagrant box add "${osName}${osVersion}.box" --name "${osName}$osVersion" --force
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
