require 'rails_helper'

describe 'Newsletter subscriptions', type: :request do
  let(:valid_email) { 'testuser@example.com' }
  let(:invalid_email) { 'not-an-email' }

  it 'subscribes with a valid email (JSON)' do
    post newsletters_path, params: { newsletter: { email: valid_email } }, as: :json
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)['status']).to eq('success')
    expect(Newsletter.exists?(email: valid_email)).to be true
  end

  it 'does not subscribe with an invalid email (JSON)' do
    post newsletters_path, params: { newsletter: { email: invalid_email } }, as: :json
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)['status']).to eq('error')
    expect(Newsletter.exists?(email: invalid_email)).to be false
  end

  it 'does not allow duplicate subscriptions (JSON)' do
    Newsletter.create!(email: valid_email)
    post newsletters_path, params: { newsletter: { email: valid_email } }, as: :json
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)['status']).to eq('error')
  end

  it 'subscribes with a valid email (HTML)' do
    post newsletters_path, params: { newsletter: { email: 'htmluser@example.com' } }
    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include('Thank you for subscribing')
    expect(Newsletter.exists?(email: 'htmluser@example.com')).to be true
  end
end
