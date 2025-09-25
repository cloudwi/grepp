class Test < ApplicationRecord
  validates :title, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  validate :end_date_after_start_date

  has_many :test_registrations, dependent: :destroy
  has_many :users, through: :test_registrations

  scope :available, -> { where('start_date <= ? AND end_date >= ?', Time.current, Time.current) }
  scope :upcoming, -> { where('start_date > ?', Time.current) }
  scope :past, -> { where('end_date < ?', Time.current) }

  private

  def end_date_after_start_date
    return unless start_date && end_date

    errors.add(:end_date, 'must be after start date') if end_date < start_date
  end
end