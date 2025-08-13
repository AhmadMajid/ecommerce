require 'rails_helper'

RSpec.describe ContactMessage, type: :model do
  describe 'validations' do
    let(:valid_attributes) do
      {
        name: 'John Doe',
        email: 'john@example.com',
        subject: 'Test inquiry about products',
        message: 'I would like to know more about your products and services.'
      }
    end

    context 'with valid attributes' do
      it 'is valid' do
        contact_message = ContactMessage.new(valid_attributes)
        expect(contact_message).to be_valid
      end
    end

    describe 'name validation' do
      it 'requires name to be present' do
        contact_message = ContactMessage.new(valid_attributes.merge(name: ''))
        expect(contact_message).not_to be_valid
        expect(contact_message.errors[:name]).to include("can't be blank")
      end

      it 'requires name to be at least 2 characters' do
        contact_message = ContactMessage.new(valid_attributes.merge(name: 'J'))
        expect(contact_message).not_to be_valid
        expect(contact_message.errors[:name]).to include("is too short (minimum is 2 characters)")
      end

      it 'accepts name with 2 or more characters' do
        contact_message = ContactMessage.new(valid_attributes.merge(name: 'Jo'))
        expect(contact_message).to be_valid
      end
    end

    describe 'email validation' do
      it 'requires email to be present' do
        contact_message = ContactMessage.new(valid_attributes.merge(email: ''))
        expect(contact_message).not_to be_valid
        expect(contact_message.errors[:email]).to include("can't be blank")
      end

      it 'requires email to be in valid format' do
        contact_message = ContactMessage.new(valid_attributes.merge(email: 'invalid-email'))
        expect(contact_message).not_to be_valid
        expect(contact_message.errors[:email]).to include("is invalid")
      end

      it 'accepts valid email formats' do
        valid_emails = [
          'test@example.com',
          'user.name@domain.co.uk',
          'first.last+tag@example.org'
        ]

        valid_emails.each do |email|
          contact_message = ContactMessage.new(valid_attributes.merge(email: email))
          expect(contact_message).to be_valid, "Expected #{email} to be valid"
        end
      end
    end

    describe 'subject validation' do
      it 'requires subject to be present' do
        contact_message = ContactMessage.new(valid_attributes.merge(subject: ''))
        expect(contact_message).not_to be_valid
        expect(contact_message.errors[:subject]).to include("can't be blank")
      end

      it 'requires subject to be at least 5 characters' do
        contact_message = ContactMessage.new(valid_attributes.merge(subject: 'Hi'))
        expect(contact_message).not_to be_valid
        expect(contact_message.errors[:subject]).to include("is too short (minimum is 5 characters)")
      end

      it 'accepts subject with 5 or more characters' do
        contact_message = ContactMessage.new(valid_attributes.merge(subject: 'Hello'))
        expect(contact_message).to be_valid
      end
    end

    describe 'message validation' do
      it 'requires message to be present' do
        contact_message = ContactMessage.new(valid_attributes.merge(message: ''))
        expect(contact_message).not_to be_valid
        expect(contact_message.errors[:message]).to include("can't be blank")
      end

      it 'requires message to be at least 10 characters' do
        contact_message = ContactMessage.new(valid_attributes.merge(message: 'Too short'))
        expect(contact_message).not_to be_valid
        expect(contact_message.errors[:message]).to include("is too short (minimum is 10 characters)")
      end

      it 'accepts message with 10 or more characters' do
        contact_message = ContactMessage.new(valid_attributes.merge(message: 'This is a proper message'))
        expect(contact_message).to be_valid
      end
    end
  end

  describe 'enums' do
    it 'has correct status values' do
      expect(ContactMessage.statuses).to eq({
        'pending' => 'pending',
        'read' => 'read',
        'replied' => 'replied',
        'archived' => 'archived'
      })
    end

    it 'defaults to pending status' do
      contact_message = create(:contact_message)
      expect(contact_message.status).to eq('pending')
    end
  end

  describe 'scopes' do
    describe '.recent' do
      it 'orders messages by created_at descending' do
        old_message = nil
        new_message = nil

        travel_to(2.days.ago) { old_message = create(:contact_message) }
        travel_to(1.hour.ago) { new_message = create(:contact_message) }

        messages = ContactMessage.recent.limit(2)
        expect(messages.first.created_at).to be > messages.last.created_at
        expect(messages.map(&:id)).to eq([new_message.id, old_message.id])
      end
    end

    describe '.unread' do
      let!(:read_message) { create(:contact_message, :read) }
      let!(:unread_message) { create(:contact_message) }

      it 'returns only pending messages' do
        unread_messages = ContactMessage.unread
        expect(unread_messages).to include(unread_message)
        expect(unread_messages).not_to include(read_message)
      end
    end
  end

  describe 'status transition methods' do
    let(:contact_message) { create(:contact_message) }

    describe '#mark_as_read!' do
      context 'when message is pending' do
        it 'changes status to read and sets read_at' do
          expect(contact_message.status).to eq('pending')
          expect(contact_message.read_at).to be_nil

          contact_message.mark_as_read!

          contact_message.reload
          expect(contact_message.status).to eq('read')
          expect(contact_message.read_at).to be_present
          expect(contact_message.read_at).to be_within(1.second).of(Time.current)
        end
      end

      context 'when message is not pending' do
        it 'can update read_at for already read message' do
          read_message = create(:contact_message, :read)
          original_read_at = read_message.read_at

          read_message.mark_as_read!

          read_message.reload
          expect(read_message.status).to eq('read')
          # read_at should be updated to current time
          expect(read_message.read_at).to be_within(1.second).of(Time.current)
          expect(read_message.read_at).not_to eq(original_read_at)
        end
      end
    end

    describe '#mark_as_replied!' do
      context 'when message is read' do
        it 'changes status to replied' do
          read_message = create(:contact_message, :read)
          expect(read_message.status).to eq('read')

          read_message.mark_as_replied!

          read_message.reload
          expect(read_message.status).to eq('replied')
        end
      end

      context 'when message is not read' do
        it 'can mark pending message as replied (flexible status management)' do
          pending_message = create(:contact_message)
          expect(pending_message.status).to eq('pending')

          pending_message.mark_as_replied!

          pending_message.reload
          expect(pending_message.status).to eq('replied')
        end
      end
    end
  end

  describe 'enhanced status management' do
    describe '#mark_as_pending!' do
      it 'marks read message as pending' do
        contact_message = create(:contact_message, :read)
        contact_message.mark_as_pending!

        expect(contact_message.reload.status).to eq('pending')
        expect(contact_message.read_at).to be_nil
      end

      it 'marks replied message as pending' do
        contact_message = create(:contact_message, :replied)
        contact_message.mark_as_pending!

        expect(contact_message.reload.status).to eq('pending')
        expect(contact_message.read_at).to be_nil
      end

      it 'marks archived message as pending' do
        contact_message = create(:contact_message, :archived)
        contact_message.mark_as_pending!

        expect(contact_message.reload.status).to eq('pending')
        expect(contact_message.read_at).to be_nil
      end
    end

    describe '#mark_as_read!' do
      it 'marks pending message as read and sets read_at' do
        contact_message = create(:contact_message, status: 'pending')
        contact_message.mark_as_read!

        expect(contact_message.reload.status).to eq('read')
        expect(contact_message.read_at).to be_present
      end

      it 'can mark replied message as read' do
        contact_message = create(:contact_message, :replied)
        contact_message.mark_as_read!

        expect(contact_message.reload.status).to eq('read')
        expect(contact_message.read_at).to be_present
      end

      it 'can mark archived message as read' do
        contact_message = create(:contact_message, :archived)
        contact_message.mark_as_read!

        expect(contact_message.reload.status).to eq('read')
        expect(contact_message.read_at).to be_present
      end
    end

    describe '#mark_as_replied!' do
      it 'marks pending message as replied' do
        contact_message = create(:contact_message, status: 'pending')
        contact_message.mark_as_replied!

        expect(contact_message.reload.status).to eq('replied')
      end

      it 'marks read message as replied' do
        contact_message = create(:contact_message, :read)
        contact_message.mark_as_replied!

        expect(contact_message.reload.status).to eq('replied')
      end

      it 'can mark archived message as replied' do
        contact_message = create(:contact_message, :archived)
        contact_message.mark_as_replied!

        expect(contact_message.reload.status).to eq('replied')
      end
    end
  end

  describe '#short_message' do
    let(:short_message_text) { 'This is a short message.' }
    let(:long_message_text) { 'This is a very long message that exceeds the default length limit and should be truncated with ellipsis at the end to indicate that there is more content available.' }

    it 'returns full message when shorter than limit' do
      contact_message = create(:contact_message, message: short_message_text)
      expect(contact_message.short_message).to eq(short_message_text)
    end

    it 'returns truncated message with ellipsis when longer than limit' do
      contact_message = create(:contact_message, message: long_message_text)
      result = contact_message.short_message(50)
      expect(result).to eq("#{long_message_text[0..50]}...")
      expect(result.length).to eq(54) # 50 characters + "..."
    end

    it 'uses default length of 100 when no length specified' do
      contact_message = create(:contact_message, message: long_message_text)
      result = contact_message.short_message
      expect(result).to eq("#{long_message_text[0..100]}...")
    end
  end

  describe 'factory' do
    it 'creates valid contact message' do
      contact_message = create(:contact_message)
      expect(contact_message).to be_valid
      expect(contact_message.status).to eq('pending')
    end

    it 'creates read contact message with trait' do
      contact_message = create(:contact_message, :read)
      expect(contact_message.status).to eq('read')
      expect(contact_message.read_at).to be_present
    end

    it 'creates replied contact message with trait' do
      contact_message = create(:contact_message, :replied)
      expect(contact_message.status).to eq('replied')
    end

    it 'creates archived contact message with trait' do
      contact_message = create(:contact_message, :archived)
      expect(contact_message.status).to eq('archived')
    end
  end
end
