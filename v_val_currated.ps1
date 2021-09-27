<#
.CREATED BY
    StrayTripod

.LAST MODIFIED
    9/27/2021

.SYSNOPSIS
    Validates Veeam backup jobs using the PS backup validation tool.

.DESCRIPTION 
    Run on the Veeam server. Creates a report directory, a date direcotry, runs the validation on
    backup jobs that are not disabled and are not manually scheduled on the Veeam server.
    Finally the script saves an HTML report to a new directory. The script will self manage by 
    deleting the oldest dated directory after 4 have been created. The script
    has an email finction, which will attempt to send the reports in an email address.

.NOTE
    Renamed backup jobs can not be called by name. You must call them by their backup id since 
    the new name will not be found.
#>

# setting varibles
$date=Get-Date -Format MM-dd-yyyy
$time=date
$count=Get-ChildItem $reporting | measure-Object | %{$_.Count}
$reporting='C:\Reports'
$exists=test-path $reporting
$exists2=test-path "$reporting\$date"
# Test for report direcory
if ($exists -eq $false) {
    mkdir $reporting
    } else {Write-Host 'The Reports directory exists. Moving on!'}
# .NOTE "%{$_.Count}" shorthand "foreach-object = (%) Piped-in = ($_) Count"

# Count the items in the reports folder & Delete oldest. Change the count to save more or less reports.
if ($count -gt 4) {
Get-ChildItem $reporting  |
    Sort-Object { $_.lastWriteTime } |
    Select-Object -First 1 |
    Remove-Item -recurse -Confirm:$false
}

#Load snapin & setup new validation job

Add-PSSnapin VeeamPSSnapin
$backups = get-vbrbackup
$brjobs = get-vbrjob
# get job id
function get-bkupjobid {foreach ($bkup in $backups) {write-host $bkup.jobid}}

# get backup id
function get-vbrjobid  {foreach ($job in $brjobs) {write-host $job.id}}

# Get backup jobs with a schedule
$jsch=foreach ($job in $brjobs) {if (!$job.options.joboptions.runManually){$job.info.id}}

# Get backup jobs are disabled
$disabled=foreach ($job in $brjobs) {if (!$job.info.IsScheduleEnabled){$job.info.id}}

# Get jobs with schedule that are not disabled
$validations=$jsch | Where {$disabled -NotContains $_}

# Get backup ID where jobid matches validation ID 
$valID=foreach ($id in $validations ) {get-vbrbackup | where jobid -eq $id | select -expandproperty id}

#Validation Function

set-location "C:\Program Files\Veeam\Backup and Replication\Backup"

# Test for the new report direcory
if ( $exists2 -eq $false) {
    mkdir $reporting\$date
    } else {Write-Host 'The New Reports directory exists. Moving on!'}

# setup function for the validation

function get-validate{
    foreach ($item in $valID){
     $report="$reporting\$date\$item--$date--Validation.html"  
    .\veeam.backup.validator.exe /backup:"$item" /format:html /report:"$report"
    }
}
# Run validation with measrument of duration
Measure-Command {get-validate} > $reporting\$date\timer.log 

# Write finished duration to a log

# Format the durration for email

$timer = @(Get-Content $reporting\$date\timer.log)
$days=$timer[2]
$hours=$timer[3]
$min=$timer[4]
$sec=$timer[5]

# Check for newest reports (not used)
$new_report =Get-ChildItem $reporting  |
                Sort-Object { $_.lastWriteTime } |
                Select-Object -last 1 

#Select report file names (not used)
$files=Get-ChildItem $reporting\$new_report\*.html | Select-object -ExpandProperty name 

#email
# $eReceivers="user1@example.com, user2@example.com"
$eReceiver="administrators@example.com"
$eSender="example@example.com"
$attachments=get-childitem $reporting\$date\*.html
$password = ConvertTo-SecureString 'PASSWORD' -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ('administrators@example.com', $password)
Send-MailMessage -From $eSender -SmtpServer "smtp.office365.com" -useSSL -port 587 -Credential $credential -to $eReceiver -Subject "Veeam Validation report" -Body "Here are the validation reports. `n `n The validation took: `n $days `n $hours `n $min `n $sec `n " -Attachments $attachments

