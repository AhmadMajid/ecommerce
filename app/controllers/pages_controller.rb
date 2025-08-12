class PagesController < ApplicationController
  def about
    @page_title = "About Us"
    @page_description = "Learn more about StyleMart and our commitment to quality fashion and lifestyle products."
  end

  def contact
    @page_title = "Contact Us"
    @page_description = "Get in touch with StyleMart customer support team."
    @contact = ContactForm.new
  end

  def create_contact
    @contact = ContactForm.new(contact_params)

    if @contact.valid?
      # Here you would typically send an email or save to database
      # For now, we'll just show a success message
      redirect_to contact_path, notice: "Thank you for your message! We'll get back to you soon."
    else
      @page_title = "Contact Us"
      @page_description = "Get in touch with StyleMart customer support team."
      render :contact, status: :unprocessable_entity
    end
  end

  def privacy_policy
    @page_title = "Privacy Policy"
    @page_description = "StyleMart's privacy policy and how we protect your personal information."
  end

  def terms_of_service
    @page_title = "Terms of Service"
    @page_description = "StyleMart's terms of service and user agreement."
  end

  def shipping_info
    @page_title = "Shipping Information"
    @page_description = "Information about our shipping policies, delivery times, and shipping costs."
  end

  def returns
    @page_title = "Returns & Exchanges"
    @page_description = "Our return and exchange policy to ensure your satisfaction."
  end

  def size_guide
    @page_title = "Size Guide"
    @page_description = "Find your perfect fit with our comprehensive size guide."
  end

  def faq
    @page_title = "FAQ"
    @page_description = "Frequently asked questions and answers about our products and services."
  end

  def track_order
    @page_title = "Track Your Order"
    @page_description = "Track your order status and delivery information."
  end

  def support_center
    @page_title = "Support Center"
    @page_description = "Get help and support for your shopping experience."
  end

  def wholesale
    @page_title = "Wholesale"
    @page_description = "Wholesale opportunities and business partnerships with StyleMart."
  end

  def gift_cards
    @page_title = "Gift Cards"
    @page_description = "Purchase and redeem StyleMart gift cards."
  end

  private

  def contact_params
    params.require(:contact_form).permit(:name, :email, :subject, :message)
  end
end
