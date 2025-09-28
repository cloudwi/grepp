module ApiErrorHandler
  extend ActiveSupport::Concern

  included do
    # Global error handling for common exceptions
    rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
  end

  private

  def handle_record_not_found(exception)
    resource_name = if exception.model.is_a?(String)
      exception.model.constantize.model_name.human.downcase
    else
      exception.model.model_name.human.downcase
    end
    render json: error_response("#{resource_name}을(를) 찾을 수 없습니다."), status: :not_found
  end

  def handle_record_invalid(exception)
    render json: error_response(
      "처리 중 오류가 발생했습니다.",
      exception.record.errors.full_messages
    ), status: :unprocessable_entity
  end

  def handle_service_error(exception, status = :unprocessable_entity)
    render json: error_response(exception.message), status: status
  end
end
