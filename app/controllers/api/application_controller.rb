class Api::ApplicationController < ApplicationController
  # Skip CSRF protection for API requests
  skip_before_action :verify_authenticity_token
  
  protected
  
  def render_json_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end
  
  def render_paginated_json(collection, total_count, offset = 0)
    render json: {
      total: total_count,
      offset: offset,
      data: collection
    }
  end
end