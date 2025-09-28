class PaymentCancellationService
  def initialize(payment)
    @payment = payment
  end

  def call
    validate_cancellation!

    ActiveRecord::Base.transaction do
      cancel_payment_and_registration
    end
  end

  private

  attr_reader :payment

  def validate_cancellation!
    unless %w[ completed ].include?(payment.status)
      raise CancellationError, "완료된 결제만 취소할 수 있습니다."
    end

    if completion_checked?(payment.payable)
      raise CancellationError, "이미 완료된 항목은 취소할 수 없습니다."
    end
  end

  def completion_checked?(payable)
    case payable
    when TestRegistration
      payable.completed_at.present?
    when CourseRegistration
      payable.completed_at.present?
    else
      false
    end
  end

  def cancel_payment_and_registration
    # 결제 취소
    payment.update!(
      status: "cancelled",
      cancelled_at: Time.current
    )

    # 등록 정보 삭제
    payment.payable.destroy!

    {
      payment_id: payment.id,
      status: payment.status,
      cancelled_at: payment.cancelled_at,
      refunded_amount: payment.amount
    }
  end

  class CancellationError < StandardError; end
end
