RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :feature

  # Ensure Devise is properly configured in test environment
  config.before(:suite) do
    # Ensure Devise mappings are loaded
    Devise.setup do |devise_config|
      # Ensure the User model is properly mapped
      devise_config.case_insensitive_keys = [:email]
      devise_config.strip_whitespace_keys = [:email]
    end

    # Force reload Devise mappings
    Devise.mappings[:user] = Devise.mappings[:user]
  end

  # Clear any authentication state before each test
  config.before(:each, type: :request) do
    # Clear any existing Warden state
    if respond_to?(:logout)
      logout
    end
  end
end
