# frozen_string_literal: true

class ErrorsController < ApplicationController

  def not_found
    respond_to do |format|
      format.html { render status: :not_found }
    end
  rescue ActionController::UnknownFormat
    head :not_found
  end

  def internal_error
    respond_to do |format|
      format.html { render status: :internal_server_error }
    end
  rescue ActionController::UnknownFormat
    head :internal_server_error
  end
end
