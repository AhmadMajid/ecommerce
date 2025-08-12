require 'rails_helper'

RSpec.describe 'Admin Contact Messages Management', type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:regular_user) { create(:user) }

  describe 'Admin Contact Messages Workflow' do
    before do
      # Sign in admin user using POST to session path for request specs
      post user_session_path, params: {
        user: {
          email: admin_user.email,
          password: admin_user.password
        }
      }
    end

    describe 'GET /admin/contact_messages' do
      let!(:pending_message) { create(:contact_message, name: 'John Doe', subject: 'Product inquiry') }
      let!(:read_message) { create(:contact_message, :read, name: 'Jane Smith') }

      it 'displays the admin contact messages index' do
        get admin_contact_messages_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Contact Messages')
        expect(response.body).to include('John Doe')
        expect(response.body).to include('Jane Smith')
        expect(response.body).to include('Product inquiry')
      end

      it 'displays message counts and status badges' do
        get admin_contact_messages_path

        expect(response.body).to include('pending')
        expect(response.body).to include('read')
      end

      it 'includes search and filter functionality' do
        get admin_contact_messages_path

        expect(response.body).to include('name="search"')
        expect(response.body).to include('name="status"')
      end

      it 'includes bulk action controls' do
        get admin_contact_messages_path

        expect(response.body).to include('bulk_action')
        expect(response.body).to include('mark_as_read')
        expect(response.body).to include('mark_as_replied')
        expect(response.body).to include('archive')
        expect(response.body).to include('delete')
      end
    end

    describe 'GET /admin/contact_messages/:id' do
      let(:contact_message) { create(:contact_message) }

      it 'displays the contact message details' do
        get admin_contact_message_path(contact_message)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(CGI.escapeHTML(contact_message.name))
        expect(response.body).to include(contact_message.email)
        expect(response.body).to include(contact_message.subject)
        expect(response.body).to include(contact_message.message)
      end

      it 'automatically marks pending message as read' do
        expect(contact_message.status).to eq('pending')

        get admin_contact_message_path(contact_message)

        contact_message.reload
        expect(contact_message.status).to eq('read')
      end
    end

    describe 'PATCH /admin/contact_messages/:id/mark_as_read' do
      let(:contact_message) { create(:contact_message) }

      it 'marks message as read' do
        patch mark_as_read_admin_contact_message_path(contact_message)

        expect(response).to redirect_to(admin_contact_messages_path)
        expect(flash[:notice]).to eq('Message marked as read.')

        contact_message.reload
        expect(contact_message.status).to eq('read')
      end
    end

    describe 'PATCH /admin/contact_messages/:id/mark_as_replied' do
      let(:contact_message) { create(:contact_message, :read) }

      it 'marks read message as replied' do
        patch mark_as_replied_admin_contact_message_path(contact_message)

        expect(response).to redirect_to(admin_contact_messages_path)
        expect(flash[:notice]).to eq('Message marked as replied.')

        contact_message.reload
        expect(contact_message.status).to eq('replied')
      end
    end

    describe 'DELETE /admin/contact_messages/:id' do
      let!(:contact_message) { create(:contact_message) }

      it 'deletes the contact message' do
        expect {
          delete admin_contact_message_path(contact_message)
        }.to change(ContactMessage, :count).by(-1)

        expect(response).to redirect_to(admin_contact_messages_path)
        expect(flash[:notice]).to eq('Message deleted successfully.')
      end
    end

    describe 'POST /admin/contact_messages/bulk_action' do
      let!(:message1) { create(:contact_message) }
      let!(:message2) { create(:contact_message) }

      it 'performs bulk mark as read' do
        post bulk_action_admin_contact_messages_path, params: {
          bulk_action: 'mark_as_read',
          message_ids: [message1.id, message2.id]
        }

        expect(response).to redirect_to(admin_contact_messages_path)
        expect(flash[:notice]).to include('marked as read')

        message1.reload
        message2.reload
        expect(message1.status).to eq('read')
        expect(message2.status).to eq('read')
      end

      it 'performs bulk delete' do
        expect {
          post bulk_action_admin_contact_messages_path, params: {
            bulk_action: 'delete',
            message_ids: [message1.id, message2.id]
          }
        }.to change(ContactMessage, :count).by(-2)

        expect(response).to redirect_to(admin_contact_messages_path)
        expect(flash[:notice]).to include('deleted')
      end
    end

    describe 'filtering and searching' do
      let!(:john_message) { create(:contact_message, name: 'John Doe', email: 'john@example.com') }
      let!(:jane_message) { create(:contact_message, :read, name: 'Jane Smith', subject: 'Support request') }

      it 'filters by status' do
        get admin_contact_messages_path, params: { status: 'pending' }

        expect(response.body).to include('John Doe')
        expect(response.body).not_to include('Jane Smith')
      end

      it 'searches by name' do
        get admin_contact_messages_path, params: { search: 'John' }

        expect(response.body).to include('John Doe')
        expect(response.body).not_to include('Jane Smith')
      end

      it 'searches by email' do
        get admin_contact_messages_path, params: { search: 'john@example.com' }

        expect(response.body).to include('John Doe')
        expect(response.body).not_to include('Jane Smith')
      end

      it 'combines filters' do
        get admin_contact_messages_path, params: { status: 'read', search: 'Jane' }

        expect(response.body).to include('Jane Smith')
        expect(response.body).not_to include('John Doe')
      end
    end
  end

  describe 'Authentication and Authorization' do
    describe 'when not authenticated' do
      it 'redirects to login page' do
        get admin_contact_messages_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'when authenticated as regular user' do
      before do
        # Sign out admin and sign in regular user
        delete destroy_user_session_path
        post user_session_path, params: {
          user: {
            email: regular_user.email,
            password: regular_user.password
          }
        }
      end

      it 'redirects to root with access denied message' do
        get admin_contact_messages_path

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied. Admin privileges required.')
      end
    end

    describe 'when authenticated as admin' do
      before do
        post user_session_path, params: {
          user: {
            email: admin_user.email,
            password: admin_user.password
          }
        }
      end

      it 'allows access to admin contact messages' do
        get admin_contact_messages_path

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'Error handling' do
    before do
      post user_session_path, params: {
        user: {
          email: admin_user.email,
          password: admin_user.password
        }
      }
    end

    it 'handles non-existent contact message gracefully' do
      get admin_contact_message_path(id: 999999)
      expect(response).to have_http_status(:not_found)
    end

    it 'handles invalid bulk action parameters' do
      message = create(:contact_message)

      post bulk_action_admin_contact_messages_path, params: {
        bulk_action: 'invalid_action',
        message_ids: [message.id]
      }

      expect(response).to redirect_to(admin_contact_messages_path)
      expect(flash[:alert]).to eq('Invalid action selected.')
    end

    it 'handles bulk action with no messages selected' do
      post bulk_action_admin_contact_messages_path, params: {
        bulk_action: 'mark_as_read'
        # Omitting message_ids entirely
      }

      expect(response).to redirect_to(admin_contact_messages_path)

      # Follow the redirect to see the flash message
      follow_redirect!
      expect(response.body).to include('No messages selected.')
    end
  end
end
