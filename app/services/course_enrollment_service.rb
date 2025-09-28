class CourseEnrollmentService
  def initialize(user, course, enrollment_params)
    @user = user
    @course = course
    @enrollment_params = enrollment_params
  end

  def call
    validate_enrollment!

    ActiveRecord::Base.transaction do
      create_registration_and_payment
    end
  end

  private

  attr_reader :user, :course, :enrollment_params

  def validate_enrollment!
    if user.course_registrations.exists?(course: course)
      raise EnrollmentError, "이미 신청한 수업입니다."
    end

    if enrollment_params[:amount].to_d != course.price
      raise EnrollmentError, "결제 금액이 수업 가격과 일치하지 않습니다."
    end
  end

  def create_registration_and_payment
    course_registration = user.course_registrations.create!(course: course)

    payment = Payment.create!(
      user: user,
      payable: course_registration,
      amount: course.price,
      payment_method: normalized_payment_method,
      status: "completed",
      payment_time: Time.current
    )

    {
      registration_id: course_registration.id,
      course_id: course.id,
      course_title: course.title,
      payment: {
        id: payment.id,
        amount: payment.amount,
        payment_method: payment.payment_method,
        status: payment.status,
        payment_time: payment.payment_time
      }
    }
  end

  def normalized_payment_method
    case enrollment_params[:payment_method].downcase
    when "kakaopay", "kakao"
      "paypal"
    when "card", "credit"
      "credit_card"
    when "bank"
      "bank_transfer"
    else
      "paypal"
    end
  end

  class EnrollmentError < StandardError; end
end