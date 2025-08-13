require 'rails_helper'

RSpec.describe AdminMailer, type: :mailer do
  describe '#reply_to_contact_message' do
    let(:contact_message) do
      create(:contact_message,
        name: 'John Doe',
        email: 'john@example.com',
        subject: 'Product Inquiry',
        message: 'I am interested in your winter collection.'
      )
    end
    let(:reply_content) { 'Thank you for your inquiry! We will get back to you soon.' }
    let(:admin_email) { 'admin@yourstore.com' }

    let(:mail) { AdminMailer.reply_to_contact_message(contact_message, reply_content, admin_email) }

    it 'renders the headers' do
      expect(mail.to).to eq([contact_message.email])
      expect(mail.from).to eq([admin_email])
      expect(mail.subject).to eq("Re: #{contact_message.subject}")
    end

    it 'renders the body with reply content' do
      expect(mail.body.encoded).to include(reply_content)
    end

    it 'includes original message context in body' do
      expect(mail.body.encoded).to include(contact_message.name)
      expect(mail.body.encoded).to include(contact_message.subject)
      expect(mail.body.encoded).to include(contact_message.message)
    end

    it 'includes formatted creation date' do
      expected_date = contact_message.created_at.strftime("%B %d, %Y at %I:%M %p")
      expect(mail.body.encoded).to include(expected_date)
    end

    context 'with default admin email' do
      let(:mail) { AdminMailer.reply_to_contact_message(contact_message, reply_content) }

      it 'uses default from address when admin_email is nil' do
        expect(mail.from).to eq(['admin@yourstore.com'])
      end
    end

    context 'with HTML and text parts' do
      it 'generates multipart email with both HTML and text' do
        expect(mail.multipart?).to be true
        expect(mail.parts.map(&:content_type)).to include(
          'text/html; charset=UTF-8',
          'text/plain; charset=UTF-8'
        )
      end

      it 'includes reply content in text part' do
        text_part = mail.parts.find { |part| part.content_type.include?('text/plain') }
        expect(text_part.body.decoded).to include(reply_content)
      end

      it 'includes reply content in HTML part' do
        html_part = mail.parts.find { |part| part.content_type.include?('text/html') }
        expect(html_part.body.decoded).to include(reply_content)
      end
    end

    describe 'email template rendering' do
      it 'renders HTML template without errors' do
        expect { mail.html_part.body.decoded }.not_to raise_error
      end

      it 'renders text template without errors' do
        expect { mail.text_part.body.decoded }.not_to raise_error
      end

      it 'includes proper HTML structure' do
        html_body = mail.html_part.body.decoded
        expect(html_body).to include('<!DOCTYPE html>')
        expect(html_body).to include('<html>')
        expect(html_body).to include('</html>')
      end

      it 'includes footer attribution in both formats' do
        html_body = mail.html_part.body.decoded
        text_body = mail.text_part.body.decoded

        expect(html_body).to include('contact form')
        expect(text_body).to include('contact form')
      end
    end
  end
end
