# Veeam_Validate

.CREATED BY
    StrayTripod
</br>
.LAST MODIFIED
    1/25/2021
</br>
.SYSNOPSIS
    Validates Veeam backup jobs using the PowerShell backup validation tool.
</br>
.DESCRIPTION 
    Run on this script on a Veeam server. Script will creates a report directory, a date direcotry,  then runs the validation on
    all backup job found on the Veeam server and finally saves an HTML report to the new directory. The script will self manage
    by deleting the oldest date direcotry after 4 have been created. So you can use Task Scheduler to run this. The script
    has an email finction and will attempt to send the reports in an email with the amount of time it took to run.

