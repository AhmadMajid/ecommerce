class AddressesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_address, only: [:show, :edit, :update, :destroy, :set_default]

  def index
    @addresses = current_user.addresses.includes(:user)
    @shipping_addresses = @addresses.shipping
    @billing_addresses = @addresses.billing
  end

  def show
  end

  def new
    @address = current_user.addresses.build
    @address.address_type = params[:type] || 'shipping'
  end

  def edit
  end

  def create
    @address = current_user.addresses.build(address_params)

    if @address.save
      redirect_to addresses_path, notice: 'Address was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @address.update(address_params)
      redirect_to addresses_path, notice: 'Address was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @address.destroy
    redirect_to addresses_path, notice: 'Address was successfully deleted.'
  end

  def set_default
    @address.set_as_default!
    redirect_to addresses_path, notice: 'Default address updated.'
  end

  private

  def set_address
    @address = current_user.addresses.find(params[:id])
  end

  def address_params
    params.require(:address).permit(
      :address_type, :first_name, :last_name, :company,
      :address_line_1, :address_line_2, :city, :state_province,
      :postal_code, :country, :phone, :default_address
    )
  end
end
