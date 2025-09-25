class CourseRegistration < ApplicationRecord
  belongs_to :user
  belongs_to :course

  validates :user_id, presence: true
  validates :course_id, presence: true
  validates :registration_time, presence: true
  validates :status, presence: true, inclusion: { in: %w[enrolled active completed dropped cancelled] }

  validate :registration_within_enrollment_period

  scope :enrolled, -> { where(status: 'enrolled') }
  scope :active, -> { where(status: 'active') }
  scope :completed, -> { where(status: 'completed') }
  scope :dropped, -> { where(status: 'dropped') }
  scope :cancelled, -> { where(status: 'cancelled') }

  before_validation :set_registration_time, on: :create

  private

  def registration_within_enrollment_period
    return unless course && registration_time

    if registration_time < course.enrollment_start_date || registration_time > course.enrollment_end_date
      errors.add(:registration_time, 'must be within enrollment period')
    end
  end

  def set_registration_time
    self.registration_time ||= Time.current
  end
end