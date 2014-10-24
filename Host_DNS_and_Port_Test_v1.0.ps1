<# --- [Host_DNS_and_Port_Test_v1.0.ps1] PowerShell Script ---

Author(s):           Ryan Irujo
Inception:           10.21.2014
Last Modified:       10.22.2014

Description:         Script performs a DNS and set of Port Checks based upon a list of Hosts provided in a text file
                     named 'Hosts.txt' Results are returned in CSV Format.


Changes:             10.22.2014 - R. Irujo
		    - Added Documentation


Additional Notes:    To test multiple ports, provide values separated by commas. i.e. - 443,3389

                     The 'Hosts.txt' file that is read into the Script must be have 'Hostname' as the first
		     entry in the list. An Example list is shown below.
					 
		     Hostname
		     TESTSRV101
		     TESTSRV102
		     TESTSRV103
					 
					 
Standard Syntax:     ./Host_DNS_and_Port_Test_v1.0.ps1

Example:             ./Host_DNS_and_Port_Test_v1.0.ps1 80,3389
#>

param($Ports)

Clear-Host

# Checking Parameter Values.
if (!$Ports) 
{
	Write-Host "A Port Number or Multiple Port Numbers must be provided, i.e. - 80 or 80,443,3389."
	exit 2;
}

# Spliting up the '$Ports' Variable into an Array if multiple values are detected.
if ($Ports -match ",")
{
	$Ports = $Ports.Split(",")
}

# Declaring Standard Variables.
$HostNames   = @()
$HostResults = @()
$HostNames   = Import-CSV ".\Hosts.txt"


Foreach ($Entry in $HostNames) 
{

    $HostResult = New-Object -TypeName PSObject
    $HostResult | Add-Member -MemberType NoteProperty -Name HostName -Value ""
    $HostResult | Add-Member -MemberType NoteProperty -Name DNSResultHostName -Value ""

	$HostResult.HostName = $Entry.Hostname

	# Checking if Host is Resolvable via DNS.
    try 
	{
		$DNS_Entry = [System.Net.DNS]::GetHostByName("$($Entry.Hostname)")
		$HostResult.DNSResultHostName = "$($DNS_Entry.AddressList.IPAddressToString)"
	}
	catch [System.Exception] 
	{
		$HostResult.DNSResultHostName = "$_"
	}

	# Checking to see if the Port(s) are open and available.
	ForEach ($Port in $Ports)
	{
		
		$NoteProperty_PortNumber = "PortCheck_$Port"
		$HostResult | Add-Member -MemberType NoteProperty -Name $NoteProperty_PortNumber -Value ""
		
		try 
		{
			 $Socket = New-Object Net.Sockets.TcpClient
			 $Socket.Connect($Entry.Hostname, $Port)
			 $HostResult.$NoteProperty_PortNumber = "Open"
		}
		catch [System.Exception]
		{
			$HostResult.$NoteProperty_PortNumber = "$_"
		}	
	}
	
	# Adding Final Results to the '$HostResults' Variable.
	$HostResults += $HostResult
}

# Creating Timestamp for the 'SCOMLinuxAgentInstallResults.csv' File.
$TimeStamp = Get-Date -Format "yyyy.MM.dd-HH.mm.ss"

# Exporting the data in the '$HostResults' Array out to the 'SCOMLinuxAgentInstallResults.csv' File.
$HostResults | Export-Csv -Path ".\Host_DNS_and_Port_Check_Results_$TimeStamp.csv" -NoTypeInformation

# Sending Final Results to Console as well.
$HostResults | FT


