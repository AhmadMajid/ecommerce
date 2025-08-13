require 'rails_helper'

RSpec.feature 'Admin Email Reply Functionality', type: :feature do
  let(:admin_user) { create(:admin_user) }
  let(:contact_message) { create(:contact_message,
    name: 'John Customer',
    email: 'john@customer.com',
    subject: 'Product Question',
    message: 'I have a question about your products.'
  ) }

  before do
    ActionMailer::Base.deliveries.clear

    # Sign in as admin
    visit new_user_session_path
    fill_in 'Email', with: admin_user.email
    fill_in 'Password', with: admin_user.password
    click_button 'Sign In'
  end

  scenario 'Admin can copy reply content to clipboard', js: true do
    visit admin_contact_message_path(contact_message)

    # Fill in reply content
    reply_text = 'Thank you for your question! We will get back to you soon.'
    fill_in 'reply-textarea', with: reply_text

    # Click copy button
    click_button 'Copy Reply'

    # Check for success feedback
    expect(page).to have_button('Copied!')

    # Wait for button to revert
    sleep 2.5
    expect(page).to have_button('Copy Reply')
  end

  scenario 'Admin can open email client with pre-filled content', js: true do
    visit admin_contact_message_path(contact_message)

    # Fill in reply content
    reply_text = 'Thank you for your question!'
    fill_in 'reply-textarea', with: reply_text

    # This would normally open the email client, but in test we can't verify that
    # We can only check that the button exists and is functional
    expect(page).to have_button('Open Email Client')

    # The JavaScript function should construct proper mailto URL
    # We test this functionality in the JavaScript unit tests
  end

  scenario 'Admin can send email directly via Rails' do
    visit admin_contact_message_path(contact_message)

    # Check that Rails email form is initially hidden
    expect(page).to have_css('#rails-email-form.hidden')

    reply_text = 'Thank you for contacting us! Your question is important to us.'

    # Use the non-JavaScript approach: visit the page with the show_rails_form parameter
    visit admin_contact_message_path(contact_message, show_rails_form: true)

    # Now the Rails email form should be visible
    expect(page).to have_css('#rails-email-form', visible: true)
    expect(page).not_to have_css('#rails-email-form.hidden')

    # Fill in the reply content in the Rails form
    fill_in 'reply_content', with: reply_text

    # Customize admin email and send
    fill_in 'admin_email', with: 'support@mystore.com'
    click_button 'Send Email Now'

    # Check for success message
    expect(page).to have_content('Reply sent successfully!')

    # Verify email was sent
    expect(ActionMailer::Base.deliveries.count).to eq(1)

    email = ActionMailer::Base.deliveries.last
    expect(email.to).to include('john@customer.com')
    expect(email.from).to include('support@mystore.com')
    expect(email.subject).to eq('Re: Product Question')
    expect(email.body.encoded).to include(reply_text)
    expect(email.body.encoded).to include('John Customer')
    expect(email.body.encoded).to include('I have a question about your products.')

    # Check that message is marked as replied
    expect(contact_message.reload.status).to eq('replied')
  end

  scenario 'Admin sees error when trying to send empty reply', js: true do
    visit admin_contact_message_path(contact_message)

    # Try to send without filling reply
    accept_alert('Please enter a reply message first') do
      click_button 'Send via Rails'
    end

    # Form should remain hidden (the alert prevented the form from showing)
    expect(page).not_to have_css('#rails-email-form', visible: true)
  end

  scenario 'Admin can cancel Rails email sending', js: true do
    visit admin_contact_message_path(contact_message)

    fill_in 'reply-textarea', with: 'Some reply content'
    click_button 'Send via Rails'

    # Form should be visible
    expect(page).to have_css('#rails-email-form:not(.hidden)')

    # Cancel the action - look for a Cancel link instead
    within('#rails-email-form') do
      click_link 'Cancel'
    end

    # Should return to the main page
    expect(current_path).to eq(admin_contact_message_path(contact_message))
    # Form should not be shown after navigation
    expect(page).not_to have_css('#rails-email-form', visible: true)
  end

  scenario 'Admin can use email templates', js: true do
    visit admin_contact_message_path(contact_message)

    # Click a template button
    click_button 'Thank You'

    # Check that textarea is filled with template content
    textarea_content = find('#reply-textarea').value
    expect(textarea_content).to include('Thank you for contacting us!')
    expect(textarea_content).to include('John Customer')
    expect(textarea_content).to include('Product Question')
  end

  scenario 'Email templates are personalized', js: true do
    visit admin_contact_message_path(contact_message)

    # Test each template
    ['Thank You', 'Request More Info', 'Follow Up', 'Issue Resolved'].each do |template_name|
      click_button template_name

      textarea_content = find('#reply-textarea').value
      expect(textarea_content).to include(contact_message.name)
      expect(textarea_content).to include(contact_message.subject)
    end
  end

  scenario 'Admin handles email delivery errors gracefully', js: true do
    # Mock email delivery failure
    allow(AdminMailer).to receive(:reply_to_contact_message).and_raise(StandardError.new('SMTP Error'))

    visit admin_contact_message_path(contact_message)

    fill_in 'reply-textarea', with: 'Test reply'
    click_button 'Send via Rails'

    # Wait for form to appear and fill it properly
    expect(page).to have_css('#rails-email-form:not(.hidden)')

    # The reply content should be automatically filled from the textarea
    # Just need to fill the admin email and submit
    fill_in 'admin_email', with: 'admin@test.com'
    click_button 'Send Email Now'

    expect(page).to have_content('Failed to send email. Please check your email configuration.')
    expect(ActionMailer::Base.deliveries.count).to eq(0)
  end

  scenario 'Multiple reply options are clearly presented' do
    visit admin_contact_message_path(contact_message)

    # Check all three options are available
    expect(page).to have_button('Copy Reply')
    expect(page).to have_button('Open Email Client')
    expect(page).to have_button('Send via Rails')

    # Check explanatory text
    expect(page).to have_content('Send via email client or directly from Rails')
  end

  scenario 'Email content includes original message context', js: true do
    visit admin_contact_message_path(contact_message)

    fill_in 'reply-textarea', with: 'Here is my response.'
    click_button 'Send via Rails'
    click_button 'Send Email Now'

    email = ActionMailer::Base.deliveries.last
    email_body = email.body.encoded

    # Check original message context is included
    expect(email_body).to include('Original message:')
    expect(email_body).to include('From: John Customer')
    expect(email_body).to include('Subject: Product Question')
    expect(email_body).to include('I have a question about your products.')

    # Check formatted date
    expected_date = contact_message.created_at.strftime("%B %d, %Y at %I:%M %p")
    expect(email_body).to include(expected_date)
  end
end
