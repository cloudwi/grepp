class Course < ApplicationRecord
  validates :title, presence: true
  validates :enrollment_start_date, presence: true
  validates :enrollment_end_date, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }

  validate :enrollment_end_date_after_start_date

  # Counter cache 설정으로 JOIN 없이 등록자 수 조회 가능
  has_many :course_registrations, dependent: :destroy, counter_cache: :registrations_count
  has_many :users, through: :course_registrations

  # 인덱스를 활용한 최적화된 스코프
  scope :enrollment_open, -> { where("enrollment_start_date <= ? AND enrollment_end_date >= ?", Time.current, Time.current) }
  scope :enrollment_upcoming, -> { where("enrollment_start_date > ?", Time.current) }
  scope :enrollment_closed, -> { where(enrollment_end_date: ...Time.current) }

  # 별칭 스코프 (API 일관성을 위해)
  scope :available, -> { enrollment_open }
  scope :upcoming, -> { enrollment_upcoming }
  scope :past, -> { enrollment_closed }

  # 인기순 정렬 (counter cache 활용)
  scope :popular, -> { order(registrations_count: :desc) }
  scope :by_start_date, -> { order(:enrollment_start_date) }
  scope :recent, -> { order(created_at: :desc) }

  # PostgreSQL 전문 검색 (GIN 인덱스 활용)
  scope :search_by_title, ->(query) {
    return all if query.blank?

    where("to_tsvector('simple', coalesce(title, '')) @@ plainto_tsquery('simple', ?)", query)
  }

  # 가격 범위 검색 (인덱스 활용)
  scope :price_between, ->(min_price, max_price) {
    query = all
    query = query.where(price: min_price..) if min_price.present?
    query = query.where(price: ..max_price) if max_price.present?
    query
  }

  private

  def enrollment_end_date_after_start_date
    return unless enrollment_start_date && enrollment_end_date

    errors.add(:enrollment_end_date, "must be after enrollment start date") if enrollment_end_date < enrollment_start_date
  end
end
