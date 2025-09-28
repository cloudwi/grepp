class TestApplicationService
  def initialize(user, test, application_params)
    @user = user
    @test = test
    @application_params = application_params
  end

  def call
    validate_application!

    ActiveRecord::Base.transaction do
      create_registration_and_payment
    end
  end

  private

  attr_reader :user, :test, :application_params

  def validate_application!
    if user.test_registrations.exists?(test: test)
      raise ApplicationError, "이미 신청한 시험입니다."
    end
  end

  def create_registration_and_payment
    test_registration = user.test_registrations.create!(test: test)

    payment = Payment.create!(
      user: user,
      payable: test_registration,
      amount: application_params[:amount],
      payment_method: normalized_payment_method,
      status: "completed",
      payment_time: Time.current
    )

    {
      registration_id: test_registration.id,
      test_id: test.id,
      test_title: test.title,
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
    case application_params[:payment_method].downcase
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

  class ApplicationError < StandardError; end
end