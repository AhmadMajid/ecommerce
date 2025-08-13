class Admin::ContactMessagesController < Admin::BaseController
  before_action :set_contact_message, only: [:show, :send_reply, :mark_as_pending, :mark_as_read, :mark_as_replied, :archive, :destroy]

  def index
    @contact_messages = ContactMessage.recent

    # Filter by status if provided
    if params[:status].present? && ContactMessage.statuses.key?(params[:status])
      @contact_messages = @contact_messages.where(status: params[:status])
    end

    # Filter by search term
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @contact_messages = @contact_messages.where(
        "name ILIKE ? OR email ILIKE ? OR subject ILIKE ? OR message ILIKE ?",
        search_term, search_term, search_term, search_term
      )
    end

    @pending_messages_count = ContactMessage.unread.count
  end

  def show
    @contact_message.mark_as_read! if @contact_message.pending?
  end

  def mark_as_pending
    @contact_message.mark_as_pending!
    redirect_to admin_contact_messages_path, notice: 'Message marked as pending.'
  end

  def mark_as_read
    @contact_message.mark_as_read!
    redirect_to admin_contact_messages_path, notice: 'Message marked as read.'
  end

  def mark_as_replied
    @contact_message.mark_as_replied!
    redirect_to admin_contact_messages_path, notice: 'Message marked as replied.'
  end

  def archive
    @contact_message.update!(status: 'archived')
    redirect_to admin_contact_messages_path, notice: 'Message archived.'
  end

  def destroy
    @contact_message.destroy!
    redirect_to admin_contact_messages_path, notice: 'Message deleted successfully.'
  end

  def send_reply
    reply_content = params[:reply_content]&.strip
    admin_email = params[:admin_email]&.strip

    if reply_content.blank?
      redirect_to admin_contact_message_path(@contact_message), alert: 'Reply content cannot be blank.'
      return
    end

    begin
      AdminMailer.reply_to_contact_message(@contact_message, reply_content, admin_email).deliver_now
      @contact_message.mark_as_replied!
      redirect_to admin_contact_message_path(@contact_message), notice: 'Reply sent successfully!'
    rescue => e
      Rails.logger.error "Failed to send email: #{e.message}"
      redirect_to admin_contact_message_path(@contact_message), alert: 'Failed to send email. Please check your email configuration.'
    end
  end

  def bulk_action
    message_ids = params[:message_ids] || []
    action = params[:bulk_action]

    if message_ids.blank?
      redirect_to admin_contact_messages_path, alert: 'No messages selected.'
      return
    end

    messages = ContactMessage.where(id: message_ids)

    case action
    when 'mark_as_pending'
      count = messages.update_all(status: 'pending', read_at: nil)
      redirect_to admin_contact_messages_path, notice: "#{count} messages marked as pending."
    when 'mark_as_read'
      count = messages.update_all(status: 'read', read_at: Time.current)
      redirect_to admin_contact_messages_path, notice: "#{count} messages marked as read."
    when 'mark_as_replied'
      count = messages.update_all(status: 'replied')
      redirect_to admin_contact_messages_path, notice: "#{count} messages marked as replied."
    when 'archive'
      count = messages.update_all(status: 'archived')
      redirect_to admin_contact_messages_path, notice: "#{count} messages archived."
    when 'delete'
      count = messages.count
      messages.destroy_all
      redirect_to admin_contact_messages_path, notice: "#{count} messages deleted."
    else
      redirect_to admin_contact_messages_path, alert: 'Invalid action selected.'
    end
  end

  private

  def set_contact_message
    @contact_message = ContactMessage.find(params[:id])
  end
end
