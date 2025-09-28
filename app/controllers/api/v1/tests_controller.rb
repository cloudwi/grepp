class Api::V1::TestsController < Api::V1::BaseController
  def index
    service = TestSearchService.new(params)
    tests = service.call
    render json: success_response("시험 목록 조회가 완료되었습니다.", tests)
  end

  def apply
    test = Test.find(params[:id])
    service = TestApplicationService.new(current_user, test, application_params)

    result = service.call
    render json: success_response("시험 응시 신청이 완료되었습니다.", result), status: :created
  rescue TestApplicationService::ApplicationError => e
    render json: error_response(e.message), status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: error_response("신청 처리 중 오류가 발생했습니다.", e.record.errors.full_messages), status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    render json: error_response("시험을 찾을 수 없습니다."), status: :not_found
  end

  def complete
    test = Test.find(params[:id])
    registration = current_user.test_registrations.find_by!(test: test)

    if registration.completed?
      render json: error_response("이미 완료된 시험입니다."), status: :unprocessable_entity
      return
    end

    registration.complete!

    result = {
      registration_id: registration.id,
      test_id: test.id,
      test_title: test.title,
      completed_at: registration.completed_at
    }

    render json: success_response("시험 응시가 완료되었습니다.", result), status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: error_response("시험 신청 내역을 찾을 수 없습니다."), status: :not_found
  end

  private

  def application_params
    params.permit(:amount, :payment_method).tap do |p|
      p.require(:amount)
      p.require(:payment_method)
    end
  end
end
