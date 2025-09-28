class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :payable, polymorphic: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_method, presence: true, inclusion: { in: %w[credit_card debit_card bank_transfer paypal cash] }
  validates :status, presence: true, inclusion: { in: %w[pending completed failed cancelled refunded] }
  validates :payment_time, presence: true

  scope :pending, -> { where(status: "pending") }
  scope :completed, -> { where(status: "completed") }
  scope :failed, -> { where(status: "failed") }
  scope :cancelled, -> { where(status: "cancelled") }
  scope :refunded, -> { where(status: "refunded") }

  before_validation :set_payment_time, on: :create

  def cancel!
    return false unless %w[pending].include?(status)

    update!(status: "cancelled", cancelled_at: Time.current)
  end

  def refund!
    return false unless %w[completed].include?(status)

    update!(status: "refunded", cancelled_at: Time.current)
  end

  def successful?
    status == "completed"
  end

  private

  def set_payment_time
    self.payment_time ||= Time.current
  end
end
