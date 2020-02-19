<#
.SYNOPSIS
   This script is to facilitate processing only relevant event logs with EvtxECmd.  EvtxECmd can
   only process one file 
   at a time with the "-f" switch or a directory of event logs with the "-d" switch.  The list is 
   relevant event log are contained in the EntLogs2Process.txt file.  The initial list include the 
   event logs discussed in SANS FOR508. 
.DESCRIPTION
    This script will copy event logs from the source cli parameter to the destination parameter. 
    The list of files to copy are contained in the EntLogs2Process.txt file. 
.PARAMETER source
    Required. The path of the folder containing the event logs that you wish to make a copy of. 
.PARAMETER dest
    Required.  The path of the folder where you want to copy the event logs to.  
.PARAMETER logs
    File Containing the list of event logs to copy. If not provided,  the script will look in the 
    current directory.
.PARAMETER outdir
    Optional parameter - Path for the output of EvtxECmd - default ".\out"
.PARAMETER outname
    Optional paramter - File name for the csv output of EvtxEcmd - default "EvtxEcmd.csv"
.EXAMPLE
    PS C:\Tools> .\Process-Evtx.ps1 <source_dir> <dest_dir> <logs>
    PS C:\Tools> .\Process-Evtx.ps1 -source E:\C\Windows\system32\winevt\logs -dest 
    G:\extracted_winevt -logs .\EventLogs2Process.txt
.NOTES
    Author: Mark Hallman
    Date:   2019-07-19
#>

Param (
    [Parameter(Mandatory=$True)]
    [string]$source,  # Where to find the Event Logs
    [Parameter(Mandatory=$True)]
    [string]$dest,   # Where to save Event Logs to
    [string]$logs    = ".\EventLogs2Process.txt",  #List of Event Logs to copy
    [string]$outdir  = "$dest\out",
    [string]$outname = "$dest\EvtxECmd.csv"

)

$eventid = "3,21,22,23,24,25,59,60,98,100,102,104,106,119,131,140,141,169,200,201,261,300,307,500,505,1000,1001,1002,1024,1027,1033,1034,1102,1149,4104,4105,4106,4616,4624,4625,4634,4647,4648,4661,4662,4663,4672,4688,4697,4698,4699,4700,4701,4702,4719,4720,4738,4768,4769,4771,4776,4778,4779,4798,4799,4800,4801,4802,4803,5136,5140,5142,5144,5145,5156,5857,5860,5861,6005,6006,7034,7035,7036,7040,7045,10000,10001,11707,11708,11724"
$evtxecmd_path   = "C:\Forensic Program Files\ZimmermanTools\EvtxExplorer"
$eventlogs       = (Get-Content -Path $logs) # Process Each Event Log Name in the file
$Files2CopyCount = (Get-Content -Path $logs).count

$FilesCopied   = 0  # Files copied from source to destination
$FilesExisted  = 0  # Files that already exist in destination
$FilesNotFound = 0  # Files that were not found in source
$ErroredFiles  = 0


Write-Host "`nThere are $Files2CopyCount Event Logs in list $logs to copy.`n" -ForegroundColor Yellow

foreach ($eventlog in $eventlogs) 
{

$progressPreference = 'silentlyContinue'

try 
    {
       $SourceFileExists = (Test-Path -Path $source\$eventlog)
    If ($SourceFileExists -eq $True) {
        $DestFileExists = (Test-Path -Path $dest\$eventlog)
        If ($DestFileExists -eq $False) {
            Write-Host "Copying $source\$eventlog to $dest" -ForegroundColor Green
            Copy-Item -Path $source\$eventlog -Destination $dest -Force  # Copy files using source and destination from 
            $FilesCopied++
        }
        else {
            Write-Host "$dest\$eventlog is already present in the destination dir" -ForegroundColor Yellow
            $FilesExisted++
        }
    }
    else {
        Write-Host "$eventlog is not found in the source dir" -ForegroundColor Red 
        $FilesNotFound++
    }
    }
    catch 
    {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Error copying $source\$eventlog) ($ErrorMessage)."
	$ErroredFiles++
    }
    finally 
    {
       $progressPreference = 'Continue'
        
    }

    
}

Write-Host "`n`nEvent Log Copy Complete`n" -ForegroundColor Red
Write-Host "Files Copied: $FilesCopied" -ForegroundColor Green
Write-Host "Files Already Existed in Destination: $FilesExisted" -ForegroundColor Yellow
Write-Host "Files not found in source: $FilesNotFound`n" -ForegroundColor Red 
Write-Host "File errors: $ErroredFiles`n" -ForegroundColor Red 

if ((Test-Path -Path "$evtxecmd_path\EvtxECmd.exe") -eq $False)
{
    Write-Host "Could not find evtxecmd in current working directory. Exiting`n"
    return
}
else 
{
    ."$evtxecmd_path\EvtxECmd.exe" -d $dest --csv $outdir --csvf $outname --inc $eventid   
}

