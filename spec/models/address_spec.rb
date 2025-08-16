require 'rails_helper'

RSpec.describe Address, type: :model do
  let(:user) { create(:user) }

  describe 'validations' do
    it 'validates country as 2-character ISO code' do
      address = build(:address, user: user, country: 'US')
      expect(address).to be_valid
      
      address.country = 'USA'
      expect(address).not_to be_valid
      expect(address.errors[:country]).to include('is the wrong length (should be 2 characters)')
    end
  end

  describe '#country_name' do
    it 'returns full country name for ISO codes' do
      address = build(:address, user: user, country: 'US')
      expect(address.country_name).to eq('United States')
      
      address.country = 'CA'
      expect(address.country_name).to eq('Canada')
      
      address.country = 'GB'
      expect(address.country_name).to eq('United Kingdom')
      
      # Unknown country code returns the code itself
      address.country = 'XX'
      expect(address.country_name).to eq('XX')
    end
  end

  describe '#full_name' do
    it 'combines first and last name' do
      address = build(:address, user: user, first_name: 'John', last_name: 'Doe')
      expect(address.full_name).to eq('John Doe')
    end
  end

  describe '#formatted_address' do
    it 'formats address with country name' do
      address = build(:address, 
        user: user,
        first_name: 'John',
        last_name: 'Doe',
        company: 'ACME Corp',
        address_line_1: '123 Main St',
        address_line_2: 'Apt 4B',
        city: 'New York',
        state_province: 'NY',
        postal_code: '10001',
        country: 'US'
      )
      
      formatted = address.formatted_address
      expect(formatted).to include('John Doe')
      expect(formatted).to include('ACME Corp')
      expect(formatted).to include('123 Main St')
      expect(formatted).to include('Apt 4B')
      expect(formatted).to include('New York, NY 10001')
      expect(formatted).to include('United States')
    end
  end

  describe '#set_as_default!' do
    it 'sets address as default and removes default from others' do
      address1 = create(:address, user: user, address_type: 'shipping', default_address: true)
      address2 = create(:address, user: user, address_type: 'shipping', default_address: false)
      
      address2.set_as_default!
      
      address1.reload
      address2.reload
      
      expect(address1.default_address).to be false
      expect(address2.default_address).to be true
    end
  end
end
