module InputValidator
  extend ActiveSupport::Concern

  included do
    private

    def validate_checkout_params(params)
      errors = []

      # Email validation
      if params[:email].blank?
        errors << "Email is required"
      elsif !valid_email?(params[:email])
        errors << "Email format is invalid"
      end

      # Address validation
      if params[:shipping_address].present?
        address_errors = validate_address(params[:shipping_address])
        errors.concat(address_errors)
      end

      errors
    end

    def valid_email?(email)
      email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
    end

    def validate_address(address)
      errors = []
      
      required_fields = [:first_name, :last_name, :address_line_1, :city, :state_province, :postal_code, :country]
      
      required_fields.each do |field|
        if address[field].blank?
          errors << "#{field.to_s.humanize} is required"
        end
      end

      # Postal code format validation (basic)
      if address[:postal_code].present? && !valid_postal_code?(address[:postal_code], address[:country])
        errors << "Postal code format is invalid"
      end

      errors
    end

    def valid_postal_code?(postal_code, country)
      case country&.upcase
      when 'US'
        postal_code.match?(/\A\d{5}(-\d{4})?\z/)
      when 'CA'
        postal_code.match?(/\A[A-Z]\d[A-Z] ?\d[A-Z]\d\z/i)
      else
        postal_code.present? # Basic validation for other countries
      end
    end

    def sanitize_input(input)
      return input unless input.is_a?(String)
      
      # Remove potentially harmful characters
      input.gsub(/[<>\"']/, '')
           .strip
    end
  end
end
