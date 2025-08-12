require 'rails_helper'

RSpec.describe Admin::ContactMessagesController, type: :controller do
  let(:admin_user) { create(:admin_user) }
  let(:regular_user) { create(:user) }

  before do
    sign_in admin_user
  end

  describe 'GET #index' do
    let!(:pending_message) { create(:contact_message) }
    let!(:read_message) { create(:contact_message, :read) }
    let!(:replied_message) { create(:contact_message, :replied) }

    it 'returns success' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'assigns all contact messages by default' do
      get :index
      expect(assigns(:contact_messages)).to include(pending_message, read_message, replied_message)
    end

    it 'assigns pending messages count' do
      get :index
      expect(assigns(:pending_messages_count)).to eq(1)
    end

    context 'with status filter' do
      it 'filters by pending status' do
        get :index, params: { status: 'pending' }
        expect(assigns(:contact_messages)).to include(pending_message)
        expect(assigns(:contact_messages)).not_to include(read_message, replied_message)
      end

      it 'filters by read status' do
        get :index, params: { status: 'read' }
        expect(assigns(:contact_messages)).to include(read_message)
        expect(assigns(:contact_messages)).not_to include(pending_message, replied_message)
      end

      it 'ignores invalid status' do
        get :index, params: { status: 'invalid' }
        expect(assigns(:contact_messages)).to include(pending_message, read_message, replied_message)
      end
    end

    context 'with search filter' do
      let!(:john_message) { create(:contact_message, name: 'John Doe', email: 'john@example.com') }
      let!(:jane_message) { create(:contact_message, name: 'Jane Smith', subject: 'Product inquiry') }

      it 'searches by name' do
        get :index, params: { search: 'John' }
        messages = assigns(:contact_messages)
        expect(messages).to include(john_message)
        expect(messages).not_to include(jane_message)
      end

      it 'searches by email' do
        get :index, params: { search: 'john@example.com' }
        messages = assigns(:contact_messages)
        expect(messages).to include(john_message)
        expect(messages).not_to include(jane_message)
      end

      it 'searches by subject' do
        get :index, params: { search: 'Product' }
        messages = assigns(:contact_messages)
        expect(messages).to include(jane_message)
        expect(messages).not_to include(john_message)
      end

      it 'is case insensitive' do
        get :index, params: { search: 'JOHN' }
        messages = assigns(:contact_messages)
        expect(messages).to include(john_message)
      end
    end
  end

  describe 'GET #show' do
    let(:contact_message) { create(:contact_message) }

    it 'returns success' do
      get :show, params: { id: contact_message.id }
      expect(response).to have_http_status(:success)
    end

    it 'assigns the contact message' do
      get :show, params: { id: contact_message.id }
      expect(assigns(:contact_message)).to eq(contact_message)
    end

    it 'marks pending message as read' do
      expect(contact_message.status).to eq('pending')
      get :show, params: { id: contact_message.id }
      contact_message.reload
      expect(contact_message.status).to eq('read')
    end

    it 'does not change status if already read' do
      read_message = create(:contact_message, :read)
      original_read_at = read_message.read_at

      get :show, params: { id: read_message.id }
      read_message.reload
      expect(read_message.read_at).to eq(original_read_at)
    end
  end

  describe 'PATCH #mark_as_read' do
    let(:contact_message) { create(:contact_message) }

    it 'marks message as read and redirects' do
      patch :mark_as_read, params: { id: contact_message.id }

      contact_message.reload
      expect(contact_message.status).to eq('read')
      expect(response).to redirect_to(admin_contact_messages_path)
      expect(flash[:notice]).to eq('Message marked as read.')
    end
  end

  describe 'PATCH #mark_as_replied' do
    let(:contact_message) { create(:contact_message, :read) }

    it 'marks read message as replied and redirects' do
      patch :mark_as_replied, params: { id: contact_message.id }

      contact_message.reload
      expect(contact_message.status).to eq('replied')
      expect(response).to redirect_to(admin_contact_messages_path)
      expect(flash[:notice]).to eq('Message marked as replied.')
    end
  end

  describe 'DELETE #destroy' do
    let!(:contact_message) { create(:contact_message) }

    it 'destroys the message and redirects' do
      expect {
        delete :destroy, params: { id: contact_message.id }
      }.to change(ContactMessage, :count).by(-1)

      expect(response).to redirect_to(admin_contact_messages_path)
      expect(flash[:notice]).to eq('Message deleted successfully.')
    end
  end

  describe 'POST #bulk_action' do
    let!(:message1) { create(:contact_message) }
    let!(:message2) { create(:contact_message) }
    let!(:message3) { create(:contact_message, :read) }

    context 'with no messages selected' do
      it 'redirects with alert' do
        post :bulk_action, params: { bulk_action: 'mark_as_read' }
        expect(response).to redirect_to(admin_contact_messages_path)
        expect(flash[:alert]).to eq('No messages selected.')
      end
    end

    context 'mark_as_read action' do
      it 'marks pending messages as read' do
        post :bulk_action, params: {
          bulk_action: 'mark_as_read',
          message_ids: [message1.id, message2.id, message3.id]
        }

        message1.reload
        message2.reload
        message3.reload

        expect(message1.status).to eq('read')
        expect(message2.status).to eq('read')
        expect(message3.status).to eq('read') # Should remain read
        expect(flash[:notice]).to eq('3 messages marked as read.')
      end
    end

    context 'mark_as_replied action' do
      it 'marks read messages as replied' do
        post :bulk_action, params: {
          bulk_action: 'mark_as_replied',
          message_ids: [message3.id]
        }

        message3.reload
        expect(message3.status).to eq('replied')
        expect(flash[:notice]).to eq('1 messages marked as replied.')
      end
    end

    context 'archive action' do
      it 'archives messages' do
        post :bulk_action, params: {
          bulk_action: 'archive',
          message_ids: [message1.id, message2.id]
        }

        message1.reload
        message2.reload
        expect(message1.status).to eq('archived')
        expect(message2.status).to eq('archived')
        expect(flash[:notice]).to eq('2 messages archived.')
      end
    end

    context 'delete action' do
      it 'deletes messages' do
        expect {
          post :bulk_action, params: {
            bulk_action: 'delete',
            message_ids: [message1.id, message2.id]
          }
        }.to change(ContactMessage, :count).by(-2)

        expect(flash[:notice]).to eq('2 messages deleted.')
      end
    end

    context 'invalid action' do
      it 'redirects with alert' do
        post :bulk_action, params: {
          bulk_action: 'invalid_action',
          message_ids: [message1.id]
        }

        expect(response).to redirect_to(admin_contact_messages_path)
        expect(flash[:alert]).to eq('Invalid action selected.')
      end
    end
  end

  describe 'authorization' do
    context 'when not signed in' do
      before { sign_out admin_user }

      it 'redirects to sign in page' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when signed in as regular user' do
      before do
        sign_out admin_user
        sign_in regular_user
      end

      it 'redirects to root with access denied message' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied. Admin privileges required.')
      end
    end
  end
end
