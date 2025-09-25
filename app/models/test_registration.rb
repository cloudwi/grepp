class TestRegistration < ApplicationRecord
  belongs_to :user
  belongs_to :test

  validates :user_id, presence: true
  validates :test_id, presence: true
  validates :registration_time, presence: true
  validates :status, presence: true, inclusion: { in: %w[registered started completed cancelled] }

  validate :registration_within_test_period

  scope :registered, -> { where(status: 'registered') }
  scope :started, -> { where(status: 'started') }
  scope :completed, -> { where(status: 'completed') }
  scope :cancelled, -> { where(status: 'cancelled') }

  before_validation :set_registration_time, on: :create

  private

  def registration_within_test_period
    return unless test && registration_time

    if registration_time < test.start_date || registration_time > test.end_date
      errors.add(:registration_time, 'must be within test period')
    end
  end

  def set_registration_time
    self.registration_time ||= Time.current
  end
end