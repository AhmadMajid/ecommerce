require 'rails_helper'

RSpec.describe 'Debug Admin Test', type: :system do
  let(:admin_user) { create(:admin_user) }

  it 'checks admin access' do
    puts "Admin user role: #{admin_user.role}"
    puts "Admin user admin?: #{admin_user.admin?}"
    puts "Admin user valid?: #{admin_user.valid?}"
    puts "Admin user errors: #{admin_user.errors.full_messages}" unless admin_user.valid?

    visit new_user_session_path
    fill_in 'Email', with: admin_user.email
    fill_in 'Password', with: admin_user.password
    click_button 'Sign In'

    puts "Current path after sign in: #{current_path}"

    # Check if sign in was successful
    if page.has_content?('You need to sign in')
      puts "❌ Sign in failed"
      puts "Page content: #{page.text[0..400]}"
    else
      puts "✅ Sign in successful"
    end

    visit admin_root_path
    puts "Current path after visiting admin_root_path: #{current_path}"
    puts "Page title: #{page.title}"

    if page.has_content?('Contact Messages')
      puts "✅ Contact Messages link found"
    else
      puts "❌ Contact Messages link not found"
      puts "Page content preview: #{page.text[0..200]}"
    end
  end
end
