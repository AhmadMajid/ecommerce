class HealthController < ApplicationController
  def index
    render json: {
      status: 'ok',
      timestamp: Time.current,
      database: database_check,
      version: Rails.version,
      environment: Rails.env
    }
  end

  private

  def database_check
    ActiveRecord::Base.connection.execute("SELECT 1")
    'connected'
  rescue => e
    'error'
  end
end
