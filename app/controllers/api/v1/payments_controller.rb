class Api::V1::PaymentsController < Api::V1::BaseController
  def cancel
    payment = current_user.payments.find(params[:id])
    service = PaymentCancellationService.new(payment)

    result = service.call
    render json: success_response("결제가 취소되었습니다.", result), status: :ok
  rescue PaymentCancellationService::CancellationError => e
    render json: error_response(e.message), status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    render json: error_response("결제 내역을 찾을 수 없습니다."), status: :not_found
  end

  def index
    service = PaymentSearchService.new(params, current_user)
    payments_data = service.call
    render json: success_response("결제 내역 조회가 완료되었습니다.", payments_data)
  end
end