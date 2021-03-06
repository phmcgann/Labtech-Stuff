<#########################################################################################>
#Function Declarations

Function CheckRegKeyExists ($Dir, $KeyName)
{
	
	try
	{
		$CheckIfExists = Get-ItemProperty $Dir $KeyName -ErrorAction SilentlyContinue
		if ((!$CheckIfExists) -or ($CheckIfExists.Length -eq 0))
		{
			return $false
		}
		else
		{
			return $true
		}
	}
	catch
	{
		return $false
	}
	
}

Function CheckDay
{
	Param
		(
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)]
		[string]$DayofWeek,
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)]
		[string]$PatchTimeNumber,
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)]
		[object]$TemplateObject
	)
	[Int]$TemplateErrors = 0
	Foreach ($Template in $TemplateObject)
	{
		If ($Template.PatchTime -eq 'NULL') { $IgnorePatch = 1 }
		Else { $IgnorePatch = 0 }

		If ($Template.SoftwareTime -eq 'NULL') { $IgnoreReboot = 1 }
		Else { $IgnoreReboot = 0 }
		
		#Patching Window and Reboot Window ENABLED
		If ($IgnorePatch -eq 0 -and $IgnoreReboot -eq 0)
		{
			[INT]$PatchHours = $Template.PatchTime.Substring(8, 2)
			[INT]$PatchStart = $Template.PatchTime.Substring(11, 2)
			[INT]$FullPatchStart = $Template.PatchTime.Substring(11, 2)
			[INT]$RebootHours = $Template.SoftwareTime.Substring(8, 2)
			[INT]$RebootStart = $Template.SoftwareTime.Substring(11, 2)
			[INT]$FullRebootStart = $Template.SoftwareTime.Substring(11, 2)
			[INT]$DisableRebootWindow = $Template.SoftwareTime.Substring(3, 1)
			
			IF ($Template.PatchTime -notmatch $PatchTimeNumber)
			{
                [Int]$TemplateErrors++
				$Output = "$($Template.name) is not set for $($DayofWeek) : FAIL";
				Write-log $Output
			}
			
			If ($FullPatchStart -ne $FullRebootStart)
			{
                [Int]$TemplateErrors++
				$Output = "$($Template.name) Reboot Window Does Not Start at Patch Time : FAIL";
				Write-log $Output
			}
			
			If ($PatchHours -ge $RebootHours)
			{
                [Int]$TemplateErrors++
				$Output = "$($Template.name) Reboot Window Does Not Last Past Patch Time : FAIL";
				Write-log $Output
			}
			
			IF ([INT]$PatchHours + [INT]$PatchStart -gt '24')
			{
                [Int]$TemplateErrors++
				$Output = "$($Template.name) Is attempting to span midnight!! : FAIL";
				Write-log $Output
			}
			
			IF ([INT]$RebootHours + [INT]$RebootStart -gt '24')
			{
                [Int]$TemplateErrors++
				$Output = "$($Template.name)'s Reboot Window Is attempting to span midnight!! : FAIL";
				Write-log $Output
			}
			
			IF ([INT]$DisableRebootWindow -eq 8)
			{
                [Int]$TemplateErrors++
				$Output = "$($Template.name)'s Reboot Window Is Set to Disable Reboot Window : FAIL";
				Write-log $Output
			}
			
			If ($Template.WindowsUpdateMode -ne '4' -and $Template.WindowsUpdateMode -ne '5')
			{
                [Int]$TemplateErrors++
				$Output = "$($Template.name) is not set for LabTech Mode : FAIL";
				Write-log $Output
			}
			
		}
		
		#Patching Window DISABLED and Reboot Window ENABLED
		If ($IgnorePatch -eq 1 -and $IgnoreReboot -eq 0)
		{
            [Int]$TemplateErrors++
			$Output = "$($Template.name) Does Not Have A Patch Window Enabled : FAIL";
			Write-log $Output
			
			[INT]$RebootHours = $Template.SoftwareTime.Substring(8, 2)
			[INT]$RebootStart = $Template.SoftwareTime.Substring(11, 2)
			[INT]$FullRebootStart = $Template.SoftwareTime.Substring(11, 2)
			[INT]$DisableRebootWindow = $Template.SoftwareTime.Substring(3, 1)
			
			IF ([INT]$RebootHours + [INT]$RebootStart -gt '24')
			{
				$Output = "$($Template.name)'s Reboot Window Is attempting to span midnight!! : FAIL";
				Write-log $Output
			}
			
			IF ([INT]$DisableRebootWindow -eq 8)
			{
				$Output = "$($Template.name)'s Reboot Window Is Set to Disable Reboot Window : FAIL";
				Write-log $Output
			}
			
			If ($Template.WindowsUpdateMode -ne '4' -and $Template.WindowsUpdateMode -ne '5')
			{
				$Output = "$($Template.name) is not set for LabTech Mode : FAIL";
				Write-log $Output
			}
		}
		
		#Patching Window ENABLED and Reboot Window DISABLED
		If ($IgnorePatch -eq 0 -and $IgnoreReboot -eq 1)
		{
			[Int]$TemplateErrors++
			$Output = "$($Template.name) Does Not Have A Reboot Window Enabled : FAIL";
			Write-log $Output
			
			[INT]$PatchHours = $Template.PatchTime.Substring(8, 2)
			[INT]$PatchStart = $Template.PatchTime.Substring(11, 2)
			[INT]$FullPatchStart = $Template.PatchTime.Substring(11, 2)
			
			IF ($Template.PatchTime -notmatch $PatchTimeNumber)
			{
				$Output = "$($Template.name) is not set for $($DayofWeek) : FAIL";
				Write-log $Output
			}
			
			IF ([INT]$PatchHours + [INT]$PatchStart -gt '24')
			{
				$Output = "$($Template.name) Is attempting to span midnight!! : FAIL";
				Write-log $Output
			}
			
			If ($Template.WindowsUpdateMode -ne '4' -and $Template.WindowsUpdateMode -ne '5')
			{
				$Output = "$($Template.name) is not set for LabTech Mode : FAIL";
				Write-log $Output
			}
			
		}
		
		#Patching Window and Reboot Window DISABLED
		If ($IgnorePatch -eq 1 -and $IgnoreReboot -eq 1)
		{
            [Int]$TemplateErrors++
			$Output = "$($Template.name) Does Not Have A Patch Window Enabled : FAIL";
			Write-log $Output
			
			$Output = "$($Template.name) Does Not Have A Reboot Window Enabled : FAIL";
			Write-log $Output
		}
		
	}
    
    If([Int]$TemplateErrors -eq 0)
    {
        Return "Success"
    }
}

Function Write-Log
{
	<#
	.SYNOPSIS
		A function to write ouput messages to a logfile.
	
	.DESCRIPTION
		This function is designed to send timestamped messages to a logfile of your choosing.
		Use it to replace something like write-host for a more long term log.
	
	.PARAMETER StrMessage
		The message being written to the log file.
	
	.EXAMPLE
		PS C:\> Write-Log -StrMessage 'This is the message being written out to the log.' 
	
	.NOTES
		N/A
#>
	
	Param
	(
		[Parameter(Mandatory = $True, Position = 0)]
		[String]$Message
	)

    
	add-content -path $LogFilePath -value ($Message)
    Write-Output $Message
}

<#########################################################################################>
#Variable Declarations

[String]$LogFilePath = "$env:windir/temp/Patching101Results.txt"

<#########################################################################################>
#Pre-Requisite Server Checks

If (Test-Path "$LogFilePath") 
{ 
    Remove-Item "$LogFilePath" -Force
}

$ExistCheckSQLDir = CheckRegKeyExists HKLM:\Software\Wow6432Node\Labtech\Setup MySQLDir;
$ExistCheckRootPwd = CheckRegKeyExists HKLM:\Software\Wow6432Node\Labtech\Setup RootPassword;

if ($ExistCheckSQLDir -eq $true)
{ 
    $SQLDir = (Get-ItemProperty HKLM:\Software\Wow6432Node\Labtech\Setup -name MySQLDir).MySQLDir; 
}

else 
{ 
    Write-log "Critical Error: Unable to Locate SQL Directory Registry key ( HKLM:\Software\Wow6432Node\LabTech\Setup.MySQLDir )"
    exit; 
}

if ($ExistCheckRootPwd -eq $true)
{ 
    $RootPwd = (Get-ItemProperty HKLM:\Software\Wow6432Node\Labtech\Setup -name RootPassword).RootPassword; 
}

elseif ($LabTechDir -eq $false)
{ 
    Write-Log "Critical Error: Unable to Locate Root Password Registry key ( HKLM:\Software\Wow6432Node\LabTech\Setup.RootPassword )"
    exit; 
}

<#########################################################################################>
#Check 1.0 - Get Patching EDF Information for Managed Groups

set-location $SQLDir\bin;

$GroupEDFInfo = .\mysql.exe --user=root --password=$RootPwd -e "
USE Labtech;
SELECT 
``v_extradatagroups``.``groupid``, ``mastergroups``.``fullname``, ``v_extradatagroups``.``MSP Contract Group``, ``v_extradatagroups``.``Patching covered under contract``
FROM ``v_extradatagroups``  
LEFT JOIN ``Mastergroups``
ON ``mastergroups``.groupid = ``v_extradatagroups``.groupid  
WHERE ``mastergroups``.fullname LIKE '%Managed%';" --batch -N

Foreach ($Group in $GroupEDFInfo)
{
	$Grouptemp = $Group -split '\t+'
	$objGroupInfo +=
	@([pscustomobject]@{ GroupID = $GroupTemp[0]; Name = $GroupTemp[1]; MSPContractGroup = $GroupTemp[2]; PatchingCoveredUnderContract = $GroupTemp[3]; })
}

<#########################################################################################>

#Check 1.1 - Check for Patching Covered Undered Contract and the MSP Contract Group EDF's being checked.

Write-log "###################### Beginning Group Based Checks ######################"
Write-log "`r`n"

$GroupResults = $objGroupInfo | Where-Object { ($_.PatchingCoveredUnderContract -ne '1' -or $_.MspContractGroup -ne '1') -and $_.name -like '*windows*' }

If ($GroupResults)
{
	Write-Log "Not All Managed Groups Have Required EDFs Checked : FAIL"
	
	Foreach ($Group in $GroupResults)
	{
		Write-Log ": Group Name = $($Group.name)"
	}
	
}
Else 
{ 
    Write-Log "All Group Based Checks Passed!" 
}

<#########################################################################################>
#Check 1.2 - Get Patching EDF Information for Locations

set-location $SQLDir\bin;

$LocationEDFInfo = .\mysql.exe --user=root --password=$RootPwd -e "
USE Labtech;
SELECT 
``locations``.``LocationID``, ``locations``.``Name``,``clients``.``clientid``, ``Enable Patching Servers``, 
``Enable Patching Workstations``, ``Patch Day Servers``, ``Patch Day Workstations``, 
``Server Service Plan``, ``Workstation Service Plan``, ``1 - Patch Day VM Host Role``, 
``2 - Patch Day SBS Role``, ``3 - Patch Day Domain Controller Role``, ``4 - Patch Day Exchange/MSSQL Roles``, 
``5 - Patch Day Other Window Server Roles``, ``Enable Onboarding``
FROM ``v_extradatalocations``
LEFT JOIN (``locations``,``clients``) 
ON (``locations``.``locationid`` = ``v_extradatalocations``.``locationid`` AND ``clients``.``clientid`` = ``locations``.``clientid``)
WHERE ``locations``.``Name`` != 'New Computers';" --batch -N

Foreach ($Location in $LocationEDFInfo)
{
	$LocationTemp = $Location -split '\t+'
	$objLocationInfo +=
	@([pscustomobject]@{ LocationID = $LocationTemp[0]; LocationName = $LocationTemp[1]; ClientID = $LocationTemp[2]; EnablePatchingServers = $LocationTemp[3]; EnablePatchingWorkstations = $LocationTemp[4]; PatchDayServers = $LocationTemp[5]; PatchDayWorkstations = $LocationTemp[6]; ServerServicePLan = $LocationTemp[7]; WorkstationServicePlan = $LocationTemp[8]; VMHostRole = $LocationTemp[9]; SBSRole = $LocationTemp[10]; DomainControllerRole = $LocationTemp[11]; ExchangeMSSQLRoles = $LocationTemp[12]; OtherWindowServerRoles = $LocationTemp[13]; EnableOnboarding = $LocationTemp[14] })
}

<#########################################################################################>
#Check 1.3 - Locations With No WorkStation Service Plans Selected

Write-log "`r`n"
Write-log "###################### Beginning Location Based Checks ####################"
Write-log "`r`n"

[INT]$LocationErrorCounter = 0
$LocationWorkstationResults = $objLocationInfo | Where-Object { $_.WorkstationServicePlan -eq 'Not Selected' }

If ($LocationWorkstationResults)
{
	Write-Log "The Following Locations Do Not Have a Workstation Service Plan Selected:"

	Foreach ($Location in $locationworkstationresults)
	{ 
        Write-Log "`t`t`tClientID = $($Location.clientid) - Location = $($Location.locationname)"
    }

	$LocationErrorCounter++
}

<#########################################################################################>
#Check 1.4 - Locations With No Server Service Plans Selected

$LocationServerResults = $objLocationInfo | Where-Object { $_.ServerServicePlan -eq 'Not Selected' }

If ($LocationServerResults)
{
	Write-Log "The Following Locations Do Not Have a Server Service Plan Selected:"
	
	Foreach ($Location in $LocationServerResults)
	{ 
        Write-Log "`t`t`tClientID = $($Location.clientid) - Location = $($Location.locationname)"
    }

	$LocationErrorCounter++
}

<#########################################################################################>
#Check 1.5 - Locations Without Enable Onboarding Checked

$LocationOnboardingResults = $objLocationInfo | Where-Object { $_.EnableOnboarding -ne '1' }

If ($LocationOnboardingResults)
{
	Write-Log "The Following Locations Do Not Have Enable Onboarding Checked:"
	
	Foreach ($Location in $LocationOnboardingResults)
	{ 
        Write-Log "`t`t`tClientID = $($Location.clientid) - Location = $($Location.locationname)"
    }

	$LocationErrorCounter++
}

<#########################################################################################>
#Check 1.6 - Locations Without Patching Workstations Checked

$LocationPatchingWorkstations = $objLocationInfo | Where-Object { $_.EnablePatchingWorkstations -ne '1' }

If ($LocationPatchingWorkstations)
{
	Write-log "The Following Locations Do Not Have Workstation Patching Enabled:"
	
	Foreach ($Location in $LocationPatchingWorkstations)
	{ 
        Write-log "`t`t`tClientID = $($Location.clientid) - Location = $($Location.locationname)" 
    }

	$LocationErrorCounter++
}

<#########################################################################################>
#Check 1.7 - Locations Without Patching Servers Checked

$LocationPatchingServers = $objLocationInfo | Where-Object { $_.EnablePatchingServers -ne '1' }

If ($LocationPatchingServers)
{
	Write-log "The Following Locations Do Not Have Server Patching Enabled:"
	
	Foreach ($Location in $LocationPatchingServers)
	{ 
        Write-log "`t`t`tClientID = $($Location.clientid) - Location = $($Location.locationname)"
    }

	$LocationErrorCounter++
}


<#########################################################################################>
#Check 1.8 - Locations Without A Workstation Patch Day Selected

$LocationWorkstationDay = $objLocationInfo | Where-Object { $_.PatchDayWorkstations -eq 'Not Selected' }

If ($LocationWorkstationDay)
{
	Write-log "The Following Locations Do Not Have A Workstation Patch Day Selected:"
	
	Foreach ($Location in $LocationWorkstationDay)
	{ 
        Write-log "`t`t`tClientID = $($Location.clientid) - Location = $($Location.locationname)"
    }

	$LocationErrorCounter++
}

<#########################################################################################>
#Check 1.9 - Locations Without A Server Patch Day Selected

$LocationServerDay = $objLocationInfo | Where-Object { $_.PatchDayServers -eq 'Not Selected' }

If ($LocationServerDay)
{
	Write-log  "The Following Locations Do Not Have A Server Patch Day Selected:"
	
	Foreach ($Location in $LocationServerDay)
	{ 
        Write-log  "`t`t`tClientID = $($Location.clientid) - Location = $($Location.locationname)"
    }

	$LocationErrorCounter++
}

If ($LocationErrorCounter -eq 0) 
{ 
    Write-log  "All Location Based Checks Passed!"
}

<#########################################################################################>
#Check 2.0 - Get Patching Related Template Information

set-location $SQLDir\bin;

$TemplateInfo = .\mysql.exe --user=root --password=$RootPwd -e "
use Labtech;
SELECT ``Templateid``, ``Name``, ``PatchTIme``, ``SoftwareTime``, ``WindowsUpdateMode`` 
FROM ``templates``;" --batch -N

Foreach ($Template in $TemplateInfo)
{
	$Templatetemp = $Template -split '\t+'
	$objTemplateInfo +=
	@([pscustomobject]@{ TemplateID = $TemplateTemp[0]; Name = $TemplateTemp[1]; PatchTime = $TemplateTemp[2]; SoftwareTime = $TemplateTemp[3]; WindowsUpdateMode = $TemplateTemp[4]; })
}

<#########################################################################################>
#Check 2.1 - Sunday Templates Check

Write-log "`r`n"
Write-log "###################### Beginning Template Based Checks ###################"
Write-log "`r`n"


$WorkstationTemplateSundays = $objTemplateInfo | Where-Object { $_.Name -eq 'Windows Updates Workstations - Sunday' }
$ServerTemplateSundays = $objTemplateInfo | Where-Object { $_.Name -eq 'Windows Updates Servers - Sunday' }

If ($WorkstationTemplateSundays) 
{ 
    $WksSunResults = CheckDay -DayofWeek 'Sunday' -PatchTimeNumber '2007-02' -TemplateObject $WorkstationTemplateSundays
    If($WksSunResults -eq 'Success')
    {
        Write-Log "Sunday Workstation Templates are configured correctly."
    }
}

Else 
{ 
    Write-log  "Windows Updates Workstations - Sunday Does Not Exist Or Has Been Renamed : FAIL"
}

If ($ServerTemplateSundays) 
{ 
    $SvrSunResults = CheckDay -DayofWeek 'Sunday' -PatchTimeNumber '2007-02' -TemplateObject $ServerTemplateSundays 
    If($SvrSunResults -eq 'Success')
    {
        Write-Log "Sunday Server Templates are configured correctly."
    }
}
Else 
{ 
    Write-log  "Windows Updates Servers - Sunday Does Not Exist Or Have Been Renamed : FAIL"
}


<#########################################################################################>
#Check 2.2- Monday Templates Check#

$WorkstationTemplateMondays = $objTemplateInfo | Where-Object { $_.Name -eq 'Windows Updates Workstations - Monday' }
$ServerTemplateMondays = $objTemplateInfo | Where-Object { $_.Name -eq 'Windows Updates Servers - Monday' }

If ($WorkstationTemplateMondays) 
{ 
    $WksMonResults = CheckDay -DayofWeek 'Monday' -PatchTimeNumber '2007-03' -TemplateObject $WorkstationTemplateMondays
    If($WksMonResults -eq 'Success')
    {
        Write-Log "Monday Workstation Templates are configured correctly."
    }
}

Else 
{ 
    Write-log  "Windows Updates Workstations - Monday Does Not Exist Or Has Been Renamed : FAIL"
}

If ($ServerTemplateMondays) 
{ 
    $SvrMonResults = CheckDay -DayofWeek 'Monday' -PatchTimeNumber '2007-03' -TemplateObject $ServerTemplateMondays 
    If($SvrMonResults -eq 'Success')
    {
        Write-Log "Monday Server Templates are configured correctly."
    }
}

Else 
{ 
    Write-log  "Windows Updates Servers - Monday Does Not Exist Or Have Been Renamed : FAIL"
}

<#########################################################################################>
#Check 2.3- Tuesday Templates Check#>

$WorkstationTemplateTuesdays = $objTemplateInfo | Where-Object { $_.Name -eq 'Windows Updates Workstations - Tuesday' }
$ServerTemplateTuesdays = $objTemplateInfo | Where-Object { $_.Name -eq 'Windows Updates Servers - Tuesday' }

If ($WorkstationTemplateTuesdays) 
{ 
    $WksTuesResults = CheckDay -DayofWeek 'Tuesday' -PatchTimeNumber '2007-04' -TemplateObject $WorkstationTemplateTuesdays 
    If($WksTuesResults -eq 'Success')
    {
        Write-Log "Tuesday Workstation Templates are configured correctly."
    }
}

Else 
{ 
    Write-log  "Windows Updates Workstations - Tuesday Does Not Exist Or Has Been Renamed : FAIL" 
}

If ($ServerTemplateTuesdays) 
{ 
    $SvrTuesResults  = CheckDay -DayofWeek 'Tuesday' -PatchTimeNumber '2007-04' -TemplateObject $ServerTemplateTuesdays 
    If($SvrTuesResults -eq 'Success')
    {
        Write-Log "Tuesday Server Templates are configured correctly."
    }
}

Else 
{ 
    Write-log  "Windows Updates Servers - Tuesday Does Not Exist Or Have Been Renamed : FAIL"
}

<#########################################################################################>
#Check 2.4 - Wednesday Templates Check

$WorkstationTemplateWednesdays = $objTemplateInfo | Where-Object { $_.Name -eq 'Windows Updates Workstations - Wednesday' }
$ServerTemplateWednesdays = $objTemplateInfo | Where-Object { $_.Name -eq 'Windows Updates Servers - Wednesday' }

If ($WorkstationTemplateWednesdays) 
{ 
    $WksWedResults = CheckDay -DayofWeek 'Wednesday' -PatchTimeNumber '2007-05' -TemplateObject $WorkstationTemplateWednesdays 
    If($WksWedResults -eq 'Success')
    {
        Write-Log "Wednesday Workstation Templates are configured correctly."
    }
}

Else 
{ 
    Write-log  "Windows Updates Workstations - Wednesday Does Not Exist Or Has Been Renamed : FAIL"
}

If ($ServerTemplateWednesdays) 
{ 
    $SvrWedResults = CheckDay -DayofWeek 'Wednesday' -PatchTimeNumber '2007-05' -TemplateObject $ServerTemplateWednesdays 
    If($SvrWedResults -eq 'Success')
    {
        Write-Log "Wednesday Server Templates are configured correctly."
    }
}

Else 
{ 
    Write-log  "Windows Updates Servers - Wednesday Does Not Exist Or Have Been Renamed : FAIL"
}

<#########################################################################################>
#Check 2.5 - Thursday Templates Check

$WorkstationTemplateThursdays = $objTemplateInfo | Where-Object { $_.Name -eq 'Windows Updates Workstations - Thursday' }
$ServerTemplateThursdays = $objTemplateInfo | Where-Object { $_.Name -eq 'Windows Updates Servers - Thursday' }

If ($WorkstationTemplateThursdays) 
{ 
    $WksThurResults = CheckDay -DayofWeek 'Thursday' -PatchTimeNumber '2007-06' -TemplateObject $WorkstationTemplateThursdays 
    If($WksThurResults -eq 'Success')
    {
        Write-Log "Thursday Workstation Templates are configured correctly."
    }
}

Else 
{ 
    Write-log  "Windows Updates Workstations - Thursday Does Not Exist Or Has Been Renamed : FAIL" 
}

If ($ServerTemplateThursdays) 
{ 
    $SvrThurResults = CheckDay -DayofWeek 'Thursday' -PatchTimeNumber '2007-06' -TemplateObject $ServerTemplateThursdays 
    If($SvrThurResults -eq 'Success')
    {
        Write-Log "Thursday Server Templates are configured correctly."
    }
}

Else 
{ 
    Write-log  "Windows Updates Servers - Thursday Does Not Exist Or Have Been Renamed : FAIL"
}

<#########################################################################################>
#Check 2.6 - Friday Templates Check

$WorkstationTemplateFridays = $objTemplateInfo | Where-Object { $_.Name -eq 'Windows Updates Workstations - Friday' }
$ServerTemplateFridays = $objTemplateInfo | Where-Object { $_.Name -eq 'Windows Updates Servers - Friday' }

If ($WorkstationTemplateFridays) 
{ 
    $WksFriResults = CheckDay -DayofWeek 'Friday' -PatchTimeNumber '2007-07' -TemplateObject $WorkstationTemplateFridays
    If($WksFriResults -eq 'Success')
    {
        Write-Log "Friday Workstation Templates are configured correctly."
    }
}

Else 
{ 
    Write-log  "Windows Updates Workstations - Friday Does Not Exist Or Has Been Renamed : FAIL"
}

If ($ServerTemplateFridays) 
{ 
    $SvrFriResults = CheckDay -DayofWeek 'Friday' -PatchTimeNumber '2007-07' -TemplateObject $ServerTemplateFridays 
    If($SvrFriResults -eq 'Success')
    {
        Write-Log "Friday Server Templates are configured correctly."
    }
}

Else 
{ 
    Write-log  "Windows Updates Servers - Friday Does Not Exist Or Have Been Renamed : FAIL"
}

<#########################################################################################>

<#Check 2.7 - Saturday Templates Check#>

$WorkstationTemplateSaturdays = $objTemplateInfo | Where-Object { $_.Name -eq 'Windows Updates Workstations - Saturday' }
$ServerTemplateSaturdays = $objTemplateInfo | Where-Object { $_.Name -eq 'Windows Updates Servers - Saturday' }

If ($WorkstationTemplateSaturdays) 
{ 
    $WksSatResults = CheckDay -DayofWeek 'Saturday' -PatchTimeNumber '2007-08' -TemplateObject $WorkstationTemplateSaturdays 
    If($WksSatResults -eq 'Success')
    {
        Write-Log "Saturday Workstation Templates are configured correctly."
    }
}

Else 
{ 
    Write-log  "Windows Updates Workstations - Saturday Does Not Exist Or Has Been Renamed : FAIL" 
}

If ($ServerTemplateSaturdays) 
{ 
    $SvrSatResults = CheckDay -DayofWeek 'Saturday' -PatchTimeNumber '2007-08' -TemplateObject $ServerTemplateSaturdays 
    If($SvrSatResults -eq 'Success')
    {
        Write-Log "Saturday Server Templates are configured correctly."
    }
}

Else 
{ 
    Write-log  "Windows Updates Servers - Saturday Does Not Exist Or Have Been Renamed : FAIL"0; 
}

<#########################################################################################>

<#Check 2.8 - Everyday Templates Check#>


$WorkstationTemplateEveryday = $objTemplateInfo | Where-Object { $_.Name -eq 'Windows Updates Workstations - Everyday' }
$ServerTemplateEveryday = $objTemplateInfo | Where-Object { $_.Name -eq 'Windows Updates Servers - Everyday' }

If ($WorkstationTemplateEveryday) 
{
    $WksEveryResults = CheckDay -DayofWeek 'Everyday' -PatchTimeNumber '2007-09' -TemplateObject $WorkstationTemplateEveryday 
    If($WksEveryResults -eq 'Success')
    {
        Write-Log "Everyday Workstation Templates are configured correctly."
    }
}

Else 
{ 
    Write-log  "Windows Updates Workstations - Everyday Does Not Exist Or Has Been Renamed : FAIL" 
}

If ($ServerTemplateEveryday) 
{ 
    $SvrEveryResults = CheckDay -DayofWeek 'Everyday' -PatchTimeNumber '2007-09' -TemplateObject $ServerTemplateEveryday 
    If($SvrEveryResults -eq 'Success')
    {
        Write-Log "Everyday Server Templates are configured correctly."
    }
}

Else 
{ 
    Write-log  "Windows Updates Servers - Everyday Does Not Exist Or Have Been Renamed : FAIL"
}

<#########################################################################################>
#Check 2.9 - Get Patching Related Template Information

Write-Log "`r`n"
Write-Log "###################### Beginning Miscellaneous Checks ####################"
Write-Log "`r`n"


set-location $SQLDir\bin;

[INT]$HotfixGroupsInfo = .\mysql.exe --user=root --password=$RootPwd -e "
use Labtech;
SELECT COUNT(*) 
FROM ``hotfixgroups`` 
WHERE ``GroupID`` = 15;" --batch -N

If ([INT]$HotfixGroupsInfo -eq 0) 
{ 
    Write-log  "We Detected No Hotfixes approved on GroupID 15 : PASS"
}

Else 
{ 
    Write-log  "We Detected $($HotfixGroupsInfo) Hotfixes approved on GroupID 15 : FAIL" 
}