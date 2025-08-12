# Rails Ecommerce Authentication Setup Commands

## 1. Install Dependencies
bundle install

## 2. Generate Devise Configuration
rails generate devise:install

## 3. Generate User Model with Devise
rails generate devise User first_name:string last_name:string phone:string date_of_birth:date role:integer active:boolean

## 4. Generate Pundit Configuration
rails generate pundit:install

## 5. Create and Run Migrations
rails db:create
rails db:migrate

## 6. Generate Devise Views (Optional - we've already customized them)
rails generate devise:views

## 7. Create Sample Admin User (Run in Rails Console)
rails console
# Then run:
User.create!(
  email: 'admin@ecommercestore.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Admin',
  last_name: 'User',
  role: 'admin',
  confirmed_at: Time.current
)

## 8. Create Sample Customer User (Run in Rails Console)
User.create!(
  email: 'customer@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'John',
  last_name: 'Doe',
  role: 'customer',
  confirmed_at: Time.current
)

## 9. Test the Application
rails server

## 10. Open in Browser
# Visit: http://localhost:3000
# Test registration: http://localhost:3000/users/sign_up
# Test login: http://localhost:3000/users/sign_in

## 11. Test Email Configuration (Optional)
# Set up email configuration in .env file
# Test password reset functionality

## 12. Run Tests (if RSpec is set up)
bundle exec rspec

## Database Commands
# Reset database if needed
rails db:drop db:create db:migrate

# Add sample data
rails db:seed

## Production Deployment Checklist
# 1. Set environment variables for production
# 2. Configure email delivery service
# 3. Set up SSL certificates
# 4. Configure payment processor
# 5. Set up monitoring and logging
