class NewslettersController < ApplicationController
  def create
    @newsletter = Newsletter.new(newsletter_params)

    if @newsletter.save
      respond_to do |format|
        format.html do
          flash[:notice] = "Thank you for subscribing to our newsletter!"
          redirect_back(fallback_location: root_path)
        end
        format.json { render json: { status: 'success', message: 'Successfully subscribed!' } }
        format.js   { render json: { status: 'success', message: 'Successfully subscribed!' } }
      end
    else
      respond_to do |format|
        format.html do
          flash[:alert] = @newsletter.errors.full_messages.join(', ')
          redirect_back(fallback_location: root_path)
        end
        format.json { render json: { status: 'error', errors: @newsletter.errors.full_messages } }
        format.js   { render json: { status: 'error', errors: @newsletter.errors.full_messages } }
      end
    end
  end

  private

  def newsletter_params
    params.require(:newsletter).permit(:email)
  end
end
