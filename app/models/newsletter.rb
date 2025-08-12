class Newsletter < ApplicationRecord
  validates :email, presence: true,
                   format: { with: URI::MailTo::EMAIL_REGEXP },
                   uniqueness: { case_sensitive: false }

  before_save :downcase_email
  before_create :set_subscribed_at

  scope :subscribed, -> { where.not(subscribed_at: nil) }

  private

  def downcase_email
    self.email = email.downcase.strip if email.present?
  end

  def set_subscribed_at
    self.subscribed_at ||= Time.current
  end
end
