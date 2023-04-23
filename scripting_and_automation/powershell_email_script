```
#Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
$fromaddress = "Test1 <BI_Automated_Reports@corporate.net>" 
$toaddress = "Yi Cheung <ycheung@gmail.com>" 
$Subject = "Test message" 
$body = "Please find attached - test"
$file = "F:\Yi Cheung\outgoing_email\missing_SF_number_from_DFP.csv"
$smtpserver = "smtp.portal.corporate.com" 

$message = new-object System.Net.Mail.MailMessage 
$message.From = $fromaddress 
$message.To.Add($toaddress)
$message.IsBodyHtml = $True 
$message.Subject = $Subject 
$attach = new-object Net.Mail.Attachment($file,'text/plain') 
$message.Attachments.Add($attach) 

$message.body = $body 
$smtp = new-object Net.Mail.SmtpClient($smtpserver) 
$smtp.Send($message)
```
