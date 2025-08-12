require 'rails_helper'

RSpec.describe Checkout, type: :model do
  let(:user) { create(:user) }
  let(:cart) { create(:cart, user: user) }
  let(:checkout) { create(:checkout, user: user, cart: cart) }

  describe 'associations' do
    it { should belong_to(:user).optional }
    it { should belong_to(:cart) }
    it { should belong_to(:shipping_method).optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:session_id) }
    it { should validate_presence_of(:status) }

    context 'when shipping_info_step_or_later' do
      before { allow(subject).to receive(:shipping_info_step_or_later?).and_return(true) }

      it 'validates shipping_method_id presence' do
        subject.valid?
        expect(subject.errors[:shipping_method_id]).to include("can't be blank")
      end
    end

    context 'when payment_info_step_or_later' do
      before { allow(subject).to receive(:payment_info_step_or_later?).and_return(true) }

      it 'validates payment_method presence' do
        subject.valid?
        expect(subject.errors[:payment_method]).to include("can't be blank")
      end
    end
  end

  describe 'scopes' do
    it 'filters active checkouts' do
      active_checkout = create(:checkout, status: 'started')
      completed_checkout = create(:checkout, :completed)

      expect(Checkout.active).to include(active_checkout)
      expect(Checkout.active).not_to include(completed_checkout)
    end

    it 'filters expired checkouts' do
      expired_checkout = create(:checkout, :expired)
      active_checkout = create(:checkout, expires_at: 1.hour.from_now)

      expect(Checkout.expired).to include(expired_checkout)
      expect(Checkout.expired).not_to include(active_checkout)
    end
  end

  describe '#expired?' do
    it 'returns true when expires_at is in the past' do
      checkout = build(:checkout, expires_at: 1.hour.ago)
      expect(checkout.expired?).to be true
    end

    it 'returns false when expires_at is in the future' do
      checkout = build(:checkout, expires_at: 1.hour.from_now)
      expect(checkout.expired?).to be false
    end

    it 'returns false when expires_at is nil' do
      checkout = build(:checkout, expires_at: nil)
      expect(checkout.expired?).to be false
    end
  end

  describe '#guest_checkout?' do
    it 'returns true when user_id is nil' do
      checkout = build(:checkout, user: nil)
      expect(checkout.guest_checkout?).to be true
    end

    it 'returns false when user_id is present' do
      checkout = build(:checkout, user: user)
      expect(checkout.guest_checkout?).to be false
    end
  end

  describe 'address data handling' do
    let(:address_data) do
      {
        'first_name' => 'John',
        'last_name' => 'Doe',
        'address_line_1' => '123 Main St',
        'city' => 'Anytown',
        'state_province' => 'CA',
        'postal_code' => '12345',
        'country' => 'US'
      }
    end

    describe '#shipping_address_data=' do
      it 'stores address data as JSON' do
        checkout.shipping_address_data = address_data
        expect(JSON.parse(checkout.shipping_address)).to eq(address_data)
      end
    end

    describe '#shipping_address_data' do
      it 'returns parsed JSON data' do
        checkout.shipping_address = address_data.to_json
        expect(checkout.shipping_address_data).to eq(address_data)
      end

      it 'returns empty hash when shipping_address is nil' do
        checkout.shipping_address = nil
        expect(checkout.shipping_address_data).to eq({})
      end

      it 'returns empty hash when JSON is invalid' do
        checkout.shipping_address = 'invalid json'
        expect(checkout.shipping_address_data).to eq({})
      end
    end
  end

  describe 'step progression' do
    describe '#can_proceed_to_payment?' do
      it 'returns false when not in shipping_info step or later' do
        checkout = build(:checkout, status: 'started')
        expect(checkout.can_proceed_to_payment?).to be false
      end

      it 'returns false when shipping address is missing' do
        checkout = build(:checkout, status: 'shipping_info', shipping_address: nil)
        expect(checkout.can_proceed_to_payment?).to be false
      end

      it 'returns false when shipping method is missing' do
        checkout = build(:checkout,
                        status: 'shipping_info',
                        shipping_address: '{}',
                        shipping_method_id: nil)
        expect(checkout.can_proceed_to_payment?).to be false
      end

      it 'returns true when all requirements are met' do
        shipping_method = create(:shipping_method)
        checkout = build(:checkout,
                        status: 'shipping_info',
                        shipping_address: '{"first_name": "John"}',
                        shipping_method_id: shipping_method.id)
        expect(checkout.can_proceed_to_payment?).to be true
      end
    end

    describe '#can_proceed_to_review?' do
      it 'returns false when not in payment_info step or later' do
        checkout = build(:checkout, status: 'shipping_info')
        expect(checkout.can_proceed_to_review?).to be false
      end

      it 'returns false when billing address is missing' do
        checkout = build(:checkout, status: 'payment_info', billing_address: nil)
        expect(checkout.can_proceed_to_review?).to be false
      end

      it 'returns false when payment method is missing' do
        checkout = build(:checkout,
                        status: 'payment_info',
                        billing_address: '{}',
                        payment_method: nil)
        expect(checkout.can_proceed_to_review?).to be false
      end

      it 'returns true when all requirements are met' do
        checkout = build(:checkout,
                        status: 'payment_info',
                        billing_address: '{"first_name": "John"}',
                        payment_method: 'credit_card')
        expect(checkout.can_proceed_to_review?).to be true
      end
    end
  end

  describe '#progress_percentage' do
    it 'returns correct percentages for each step' do
      expect(build(:checkout, status: 'started').progress_percentage).to eq(25)
      expect(build(:checkout, status: 'shipping_info').progress_percentage).to eq(50)
      expect(build(:checkout, status: 'payment_info').progress_percentage).to eq(75)
      expect(build(:checkout, status: 'review').progress_percentage).to eq(100)
      expect(build(:checkout, status: 'completed').progress_percentage).to eq(100)
    end
  end

  describe 'callbacks' do
    describe 'before_create :set_expiry_date' do
      it 'sets expires_at to 2 hours from now' do
        travel_to(Time.current) do
          checkout = create(:checkout)
          expect(checkout.expires_at).to be_within(1.second).of(2.hours.from_now)
        end
      end
    end
  end
end
