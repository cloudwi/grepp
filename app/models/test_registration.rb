class TestRegistration < ApplicationRecord
  belongs_to :user
  belongs_to :test
  has_one :payment, as: :payable, dependent: :destroy

  validates :user_id, uniqueness: { scope: :test_id, message: "이미 신청한 시험입니다." }

  scope :completed, -> { where.not(completed_at: nil) }
  scope :pending, -> { where(completed_at: nil) }

  def complete!
    update!(completed_at: Time.current)
  end

  def completed?
    completed_at.present?
  end
end
