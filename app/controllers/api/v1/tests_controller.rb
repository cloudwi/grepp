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
    handle_service_error(e)
  end

  def complete
    test = Test.find(params[:id])
    registration = current_user.test_registrations.find_by!(test: test)

    if registration.completed?
      handle_service_error(StandardError.new("이미 완료된 시험입니다."))
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
  end

  private

  def application_params
    params.permit(:amount, :payment_method).tap do |p|
      p.require(:amount)
      p.require(:payment_method)
    end
  end
end
