class AdminMailer < ApplicationMailer
  default from: 'admin@yourstore.com'

  def reply_to_contact_message(contact_message, reply_content, admin_email = nil)
    @contact_message = contact_message
    @reply_content = reply_content
    @admin_email = admin_email || 'admin@yourstore.com'

    mail(
      to: @contact_message.email,
      subject: "Re: #{@contact_message.subject}",
      from: @admin_email
    )
  end
end
