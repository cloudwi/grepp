class Api::V1::PaymentsController < Api::V1::BaseController
  # Set up before_action filters for common operations
  before_action :set_payment, only: [:cancel]

  def index
    # Delegate search logic to service object with validated parameters
    service = PaymentSearchService.new(search_params, current_user)
    payments_data = service.call

    render json: success_response("결제 내역 조회가 완료되었습니다.", payments_data), status: :ok
  end

  def cancel
    # Delegate cancellation logic to service object
    service = PaymentCancellationService.new(@payment)
    result = service.call

    render json: success_response("결제가 취소되었습니다.", result), status: :ok
  rescue PaymentCancellationService::CancellationError => e
    # Handle specific service errors with consistent error response
    handle_service_error(e)
  end

  private

  # Strong parameters for payment search with explicit validation
  def search_params
    params.permit(:page, :per_page, :status, :from, :to, :search)
  end

  # Extract payment lookup into reusable before_action filter
  def set_payment
    @payment = current_user.payments.find(params[:id])
  end
end
