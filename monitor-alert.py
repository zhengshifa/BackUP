# -*- coding: utf-8 -*-
import smtplib
import datetime
import os
import glob
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication

# Email credentials and settings
sender_email = '804410011@qq.com'
sender_password = 'iglefswwwrwqbcif'
sender_name = 'backup error alert'

recipient_emails = ['zhengshifa@139.com']
subject = 'mysql slow_log(10.248.51.68:3306 and 10.248.64.102:3306)'
body = 'Please remember to check the attached MySQL slow logs.'

# Create a MIMEMultipart email message
message = MIMEMultipart()
message['From'] = sender_email
message['To'] = ', '.join(recipient_emails)
message['Subject'] = subject

# Add the email body text
message.attach(MIMEText(body, 'plain'))

# Get today's date and search for MySQL slow log files
today = datetime.datetime.now().strftime('%Y-%m-%d')
log_dir = '/path/to/slow_logs/'  # Update with the correct directory path
slow_log_files = glob.glob(f'{log_dir}*{today}*.log')

# Attach each slow log file to the email
for log_file in slow_log_files:
    with open(log_file, 'rb') as f:
        log_attachment = MIMEApplication(f.read())
        log_attachment.add_header('Content-Disposition', f'attachment; filename="{os.path.basename(log_file)}"')
        message.attach(log_attachment)

# Send the email
try:
    server = smtplib.SMTP_SSL('smtp.qq.com', 465)
    server.login(sender_email, sender_password)
    server.sendmail(sender_email, recipient_emails, message.as_string())
    server.quit()
    print('Email sent successfully.')
except Exception as e:
    print(f'Failed to send email: {e}')
