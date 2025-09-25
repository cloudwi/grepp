class Course < ApplicationRecord
  validates :title, presence: true
  validates :enrollment_start_date, presence: true
  validates :enrollment_end_date, presence: true

  validate :enrollment_end_date_after_start_date

  has_many :course_registrations, dependent: :destroy
  has_many :users, through: :course_registrations

  scope :enrollment_open, -> { where('enrollment_start_date <= ? AND enrollment_end_date >= ?', Time.current, Time.current) }
  scope :enrollment_upcoming, -> { where('enrollment_start_date > ?', Time.current) }
  scope :enrollment_closed, -> { where('enrollment_end_date < ?', Time.current) }

  private

  def enrollment_end_date_after_start_date
    return unless enrollment_start_date && enrollment_end_date

    errors.add(:enrollment_end_date, 'must be after enrollment start date') if enrollment_end_date < enrollment_start_date
  end
end