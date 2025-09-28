class Api::V1::CoursesController < Api::V1::BaseController
  def index
    service = CourseSearchService.new(params, current_user)
    courses_data = service.call
    render json: success_response("코스 목록 조회가 완료되었습니다.", courses_data)
  end

  def enroll
    course = Course.find(params[:id])
    service = CourseEnrollmentService.new(current_user, course, enrollment_params)

    result = service.call
    render json: success_response("수업 수강 신청이 완료되었습니다.", result), status: :created
  rescue CourseEnrollmentService::EnrollmentError => e
    render json: error_response(e.message), status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: error_response("신청 처리 중 오류가 발생했습니다.", e.record.errors.full_messages), status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    render json: error_response("수업을 찾을 수 없습니다."), status: :not_found
  end

  def complete
    course = Course.find(params[:id])
    registration = current_user.course_registrations.find_by!(course: course)

    if registration.completed?
      render json: error_response("이미 완료된 수업입니다."), status: :unprocessable_entity
      return
    end

    registration.complete!

    result = {
      registration_id: registration.id,
      course_id: course.id,
      course_title: course.title,
      completed_at: registration.completed_at
    }

    render json: success_response("수업 수강이 완료되었습니다.", result), status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: error_response("수업 신청 내역을 찾을 수 없습니다."), status: :not_found
  end

  private

  def enrollment_params
    params.permit(:amount, :payment_method).tap do |p|
      p.require(:amount)
      p.require(:payment_method)
    end
  end
end
