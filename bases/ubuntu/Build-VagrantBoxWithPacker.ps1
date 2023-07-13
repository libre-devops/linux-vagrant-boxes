try {
    $opensslVersion = & openssl version
    Write-Host "OpenSSL is installed: $opensslVersion"
} catch {
    Write-Host "OpenSSL is not installed or not found in PATH"
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
    Write-Host "Created firewall rule for ports $startPort-$endPort"
} else {
    # If the firewall rule already exists, skip it
    Write-Host "Firewall rule for ports $startPort-$endPort already exists"
}

# Generate 6 random bytes
$bytes = New-Object Byte[] 6
(New-Object Security.Cryptography.RNGCryptoServiceProvider).GetBytes($bytes)

# Convert the bytes to base64
$randomBase64Chars = [Convert]::ToBase64String($bytes)

# Remove any non-alphanumeric characters from the base64 string
$randomBase64Chars = $randomBase64Chars -replace '[^a-zA-Z0-9]', ''

# Form the VM name
$vmName = "packer-ubuntu22.04base$randomBase64Chars"

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
    }
}

# Run Packer and clean up if a terminating error occurs
try {
    packer build -force -var "vm_name=$vmName" -var "hashed_password=$hashedPassword" .\packer.pkr.hcl
} catch {
    Cleanup
    throw $_
}

# If Packer failed, clean up the VM
if ($LASTEXITCODE -ne 0) {
    Cleanup
}
