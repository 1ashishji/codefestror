class ApplicationController < ActionController::API
  rescue_from ActiveRecord::StaleObjectError, with: :handle_stale_object
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::ParameterMissing, with: :handle_bad_request

  private

  def handle_stale_object
    render json: { error: "Conflict", message: "The record was updated by another user. Please reload and try again." }, status: :conflict
  end

  def handle_not_found
    render json: { error: "Not Found", message: "The requested resource could not be found." }, status: :not_found
  end

  def handle_bad_request(exception)
    render json: { error: "Bad Request", message: exception.message }, status: :bad_request
  end
end
