require 'rails_helper'

RSpec.describe OrderMailer, type: :mailer do
  let(:user) { create(:user) }
  let(:order) { create(:order, user: user) }

  describe '#confirmation_email' do
    let(:mail) { described_class.confirmation_email(order) }

    it 'renders the headers' do
      expect(mail.subject).to eq("Order Confirmation - #{order.order_number}")
      expect(mail.to).to eq([order.email])
      expect(mail.from).to eq(['from@example.com'])
    end

    it 'assigns order and user' do
      expect(mail.body.encoded).to match(order.order_number)
    end
  end

  describe '#payment_failed_notification' do
    let(:mail) { described_class.payment_failed_notification(order) }

    it 'renders the headers' do
      expect(mail.subject).to eq("Payment Issue - #{order.order_number}")
      expect(mail.to).to eq([order.email])
      expect(mail.from).to eq(['from@example.com'])
    end

    it 'assigns order and user' do
      expect(mail.body.encoded).to match(order.order_number)
    end
  end

  describe '#refund_notification' do
    let(:refund) { double('Stripe::Refund', amount: 2500, status: 'succeeded') }
    let(:mail) { described_class.refund_notification(order, refund) }

    it 'renders the headers' do
      expect(mail.subject).to eq("Refund Processed - #{order.order_number}")
      expect(mail.to).to eq([order.email])
      expect(mail.from).to eq(['from@example.com'])
    end

    it 'assigns order, user, and refund' do
      expect(mail.body.encoded).to match(order.order_number)
    end
  end
end
