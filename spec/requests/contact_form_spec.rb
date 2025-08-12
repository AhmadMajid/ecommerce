require 'rails_helper'

RSpec.describe 'Contact Form', type: :request do
  describe 'GET /contact' do
    it 'displays the contact page successfully' do
      get contact_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Contact Us')
      expect(response.body).to include('Send us a Message')
    end

    it 'includes all required form fields' do
      get contact_path

      expect(response.body).to include('name="contact_form[name]"')
      expect(response.body).to include('name="contact_form[email]"')
      expect(response.body).to include('name="contact_form[subject]"')
      expect(response.body).to include('name="contact_form[message]"')
      expect(response.body).to include('Send Message')
    end

    it 'includes contact information sections' do
      get contact_path

      expect(response.body).to include('Address')
      expect(response.body).to include('Phone')
      expect(response.body).to include('Email')
      expect(response.body).to include('Follow Us')
    end
  end

  describe 'POST /contact' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          contact_form: {
            name: 'John Doe',
            email: 'john@example.com',
            subject: 'Test inquiry about your products',
            message: 'I am interested in learning more about your product catalog and pricing options.'
          }
        }
      end

      it 'redirects to contact page with success message' do
        post contact_path, params: valid_params

        expect(response).to redirect_to(contact_path)
        follow_redirect!
        expect(response.body).to include("Thank you for your message")
      end

      it 'creates a ContactMessage record in the database' do
        expect {
          post contact_path, params: valid_params
        }.to change(ContactMessage, :count).by(1)

        contact_message = ContactMessage.last
        expect(contact_message.name).to eq('John Doe')
        expect(contact_message.email).to eq('john@example.com')
        expect(contact_message.subject).to eq('Test inquiry about your products')
        expect(contact_message.message).to eq('I am interested in learning more about your product catalog and pricing options.')
        expect(contact_message.status).to eq('pending')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          contact_form: {
            name: '',
            email: 'invalid-email',
            subject: 'Hi',
            message: 'Short'
          }
        }
      end

      it 'renders the contact form with validation errors' do
        post contact_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Contact Us')
      end

      it 'does not create a ContactMessage record with invalid data' do
        expect {
          post contact_path, params: invalid_params
        }.not_to change(ContactMessage, :count)
      end
    end

    context 'with missing parameters' do
      it 'handles missing contact_form parameter gracefully' do
        # Test what actually happens when no contact_form params are provided
        post contact_path, params: { some_other_param: 'value' }

        # The controller returns 400 Bad Request when required params are missing
        expect(response.status).to eq(400)
      end
    end
  end
end

RSpec.describe ContactForm, type: :model do
  describe 'validations' do
    let(:valid_attributes) do
      {
        name: 'John Doe',
        email: 'john@example.com',
        subject: 'Test inquiry about your services',
        message: 'I would like to know more about your products and services.'
      }
    end

    context 'with valid attributes' do
      it 'is valid' do
        contact = ContactForm.new(valid_attributes)
        expect(contact).to be_valid
      end
    end

    describe 'name validation' do
      it 'requires name to be present' do
        contact = ContactForm.new(valid_attributes.merge(name: ''))
        expect(contact).not_to be_valid
        expect(contact.errors[:name]).to include("can't be blank")
      end

      it 'requires name to be at least 2 characters' do
        contact = ContactForm.new(valid_attributes.merge(name: 'J'))
        expect(contact).not_to be_valid
        expect(contact.errors[:name]).to include("is too short (minimum is 2 characters)")
      end

      it 'accepts name with 2 or more characters' do
        contact = ContactForm.new(valid_attributes.merge(name: 'Jo'))
        expect(contact).to be_valid
      end
    end

    describe 'email validation' do
      it 'requires email to be present' do
        contact = ContactForm.new(valid_attributes.merge(email: ''))
        expect(contact).not_to be_valid
        expect(contact.errors[:email]).to include("can't be blank")
      end

      it 'requires email to be in valid format' do
        contact = ContactForm.new(valid_attributes.merge(email: 'invalid-email'))
        expect(contact).not_to be_valid
        expect(contact.errors[:email]).to include("is invalid")
      end

      it 'accepts valid email formats' do
        valid_emails = [
          'test@example.com',
          'user.name@domain.co.uk',
          'first.last+tag@example.org'
        ]

        valid_emails.each do |email|
          contact = ContactForm.new(valid_attributes.merge(email: email))
          expect(contact).to be_valid, "Expected #{email} to be valid"
        end
      end
    end

    describe 'subject validation' do
      it 'requires subject to be present' do
        contact = ContactForm.new(valid_attributes.merge(subject: ''))
        expect(contact).not_to be_valid
        expect(contact.errors[:subject]).to include("can't be blank")
      end

      it 'requires subject to be at least 5 characters' do
        contact = ContactForm.new(valid_attributes.merge(subject: 'Hi'))
        expect(contact).not_to be_valid
        expect(contact.errors[:subject]).to include("is too short (minimum is 5 characters)")
      end

      it 'accepts subject with 5 or more characters' do
        contact = ContactForm.new(valid_attributes.merge(subject: 'Hello'))
        expect(contact).to be_valid
      end
    end

    describe 'message validation' do
      it 'requires message to be present' do
        contact = ContactForm.new(valid_attributes.merge(message: ''))
        expect(contact).not_to be_valid
        expect(contact.errors[:message]).to include("can't be blank")
      end

      it 'requires message to be at least 10 characters' do
        contact = ContactForm.new(valid_attributes.merge(message: 'Too short'))
        expect(contact).not_to be_valid
        expect(contact.errors[:message]).to include("is too short (minimum is 10 characters)")
      end

      it 'accepts message with 10 or more characters' do
        contact = ContactForm.new(valid_attributes.merge(message: 'This is a proper message'))
        expect(contact).to be_valid
      end
    end
  end

  describe 'attributes' do
    it 'has the correct attributes' do
      contact = ContactForm.new(
        name: 'John Doe',
        email: 'john@example.com',
        subject: 'Test Subject',
        message: 'Test message content'
      )

      expect(contact.name).to eq('John Doe')
      expect(contact.email).to eq('john@example.com')
      expect(contact.subject).to eq('Test Subject')
      expect(contact.message).to eq('Test message content')
    end
  end
end
