<#
.CREATED BY
    StrayTripod

.LAST MODIFIED
    1/25/2021

.SYSNOPSIS
    Validates Veeam backup jobs using the PS backup validation tool.

.DESCRIPTION 
    Run on the Veeam server. Creates a report directory, a date direcotry, runs the validation on
    all backup job found on the Veeam server and finally saves an HTML report to the new directory. The
    script will self manage by deleting the oldest date direcotry after 4 have been created. The script
    has an email finction and will attempt to send the reports in an email.
#>

# setting varibles
$date=Get-Date -Format MM-dd-yyyy
$time=date
$count=Get-ChildItem $reporting | measure-Object | %{$_.Count}
$reporting='C:\Reports'
$exists=test-path $reporting
$exists2=test-path "$reporting\$date"
# Test for direcory
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
$jobs = get-vbrbackup

#Validation Function

set-location "C:\Program Files\Veeam\Backup and Replication\Backup"
#Check if a new reports directory exists
if ($exists2 -eq $false) {
    mkdir $reporting\$date
    } else {Write-Host 'The New Reports directory exists. Moving on!'}


# setup function for the validation

function get-validate{
    foreach ($job in $jobs){
     $jobname=$job.name
     $report="$reporting\$date\$jobname--$date--Validation.html"  
    .\veeam.backup.validator.exe /backup:"$jobname" /format:html /report:"$report"
    }
}
# run validation with measrument of duration
Measure-Command {get-validate} > $reporting\$date\timer.log 

# Write finished duration to a log

###Write-Output "Finished at: $time" > $reporting\$date\timer.log

# Setup durration for email

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
# $eReceiver="user1@example.com", "user2@example.com"
$eReceiver="administrators@example.com"
$eSender="veeam@dexample.com"
$attachments=get-childitem $reporting\$date\*.html
$password = ConvertTo-SecureString '12345679' -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ('admin@example.com.com', $password)
Send-MailMessage -From $eSender -SmtpServer "smtp.office365.com" -useSSL -port 587 -Credential $credential -to $eReceiver -Subject "Veeam Validation report" -Body "Here are the validation reports. `n `n The validation took: `n $days `n $hours `n $min `n $sec `n " -Attachments $attachments
