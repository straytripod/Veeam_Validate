# Veeam_Validate
.SYSNOPSIS
</br> Validates Veeam backup jobs using the PowerShell backup validation tool.
</br>
</br>
.DESCRIPTION 
 </br> Run on this script on a Veeam server. Script will creates a report directory, a date direcotry,  then runs the validation on
 </br> all backup job found on the Veeam server and finally saves an HTML report to the new directory. The script will self manage
 </br> by deleting the oldest date direcotry after 4 have been created. So you can use Task Scheduler to run this. The script
 </br> has an email function and will attempt to send the reports in an email with the amount of time it took to run.
</br>
</br>
Make sure you confiure the email setting and varibles within the script or it will fail when run.
