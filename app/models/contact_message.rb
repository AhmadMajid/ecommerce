class ContactMessage < ApplicationRecord
  validates :name, presence: true, length: { minimum: 2 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :subject, presence: true, length: { minimum: 5 }
  validates :message, presence: true, length: { minimum: 10 }

  enum :status, {
    pending: 'pending',
    read: 'read',
    replied: 'replied',
    archived: 'archived'
  }

  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(status: 'pending') }

  def mark_as_pending!
    update!(status: 'pending', read_at: nil)
  end

  def mark_as_read!
    update!(status: 'read', read_at: Time.current)
  end

  def mark_as_replied!
    update!(status: 'replied')
  end

  def short_message(length = 100)
    message.length > length ? "#{message[0..length]}..." : message
  end
end
