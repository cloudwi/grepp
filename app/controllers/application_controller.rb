class ApplicationController < ActionController::API
  protected

  def current_user
    @current_user ||= request.env["current_user"]
  end

  def current_user_id
    @current_user_id ||= request.env["current_user_id"]
  end

  def authenticate_user!
    unless current_user
      render json: {
        status: "error",
        message: "인증이 필요합니다.",
        errors: [ "Authentication required" ]
      }, status: :unauthorized
    end
  end
end
