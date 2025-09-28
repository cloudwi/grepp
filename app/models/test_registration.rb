class TestRegistration < ApplicationRecord
  belongs_to :user
  belongs_to :test
  has_one :payment, as: :payable, dependent: :destroy

  validates :user_id, uniqueness: { scope: :test_id, message: "이미 신청한 시험입니다." }
end
