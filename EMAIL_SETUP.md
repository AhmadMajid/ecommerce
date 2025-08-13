# Email Configuration Setup

## For Development (Testing)

The application is configured to use local SMTP for development. To test email functionality:

### Option 1: MailCatcher (Recommended for Development)
1. Install mailcatcher: `gem install mailcatcher`
2. Run mailcatcher: `mailcatcher`
3. View emails at: http://localhost:1080
4. The app will send emails to port 1025 automatically

### Option 2: Gmail SMTP (For Production-like Testing)
1. Enable 2-factor authentication on your Gmail account
2. Generate an app password: https://myaccount.google.com/apppasswords
3. Update `config/environments/development.rb`:

```ruby
config.action_mailer.smtp_settings = {
  address: 'smtp.gmail.com',
  port: 587,
  domain: 'gmail.com',
  user_name: 'your-email@gmail.com',
  password: 'your-app-password',
  authentication: 'plain',
  enable_starttls_auto: true
}
```

## For Production

Update `config/environments/production.rb` with your production SMTP settings:

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: ENV['SMTP_ADDRESS'],
  port: ENV['SMTP_PORT'],
  domain: ENV['SMTP_DOMAIN'],
  user_name: ENV['SMTP_USERNAME'],
  password: ENV['SMTP_PASSWORD'],
  authentication: 'plain',
  enable_starttls_auto: true
}
```

Set these environment variables:
- SMTP_ADDRESS
- SMTP_PORT
- SMTP_DOMAIN
- SMTP_USERNAME
- SMTP_PASSWORD

## Features Implemented

1. **Copy Reply**: Fixed JavaScript to properly copy reply text to clipboard
2. **Email Client Integration**: Opens default email client with subject and message body
3. **Rails Email Sending**: Send emails directly from Rails using ActionMailer
4. **Professional Email Templates**: HTML and text versions included
5. **Error Handling**: Proper error messages and logging

## Usage

1. Navigate to any contact message in admin
2. Use email templates or write custom reply
3. Choose from three options:
   - **Copy Reply**: Copy text to clipboard
   - **Open Email Client**: Launch default email client with pre-filled content
   - **Send via Rails**: Send immediately through Rails (requires SMTP configuration)

The Rails option will automatically mark the message as "replied" when sent successfully.
