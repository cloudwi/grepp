class Test < ApplicationRecord
  validates :title, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }

  validate :end_date_after_start_date

  # Counter cache 설정으로 JOIN 없이 등록자 수 조회 가능
  has_many :test_registrations, dependent: :destroy, counter_cache: :registrations_count
  has_many :users, through: :test_registrations

  # 인덱스를 활용한 최적화된 스코프
  scope :available, -> { where("start_date <= ? AND end_date >= ?", Time.current, Time.current) }
  scope :upcoming, -> { where("start_date > ?", Time.current) }
  scope :past, -> { where(end_date: ...Time.current) }

  # 인기순 정렬 (counter cache 활용)
  scope :popular, -> { order(registrations_count: :desc) }
  scope :by_start_date, -> { order(:start_date) }
  scope :recent, -> { order(created_at: :desc) }

  # PostgreSQL 전문 검색 (GIN 인덱스 활용)
  scope :search_by_title, ->(query) {
    return all if query.blank?

    where("to_tsvector('simple', coalesce(title, '')) @@ plainto_tsquery('simple', ?)", query)
  }

  # 가격 범위 검색 (인덱스 활용)
  scope :price_between, ->(min_price, max_price) {
    query = all
    query = query.where('price >= ?', min_price) if min_price.present?
    query = query.where('price <= ?', max_price) if max_price.present?
    query
  }

  private

  def end_date_after_start_date
    return unless start_date && end_date

    errors.add(:end_date, "must be after start date") if end_date < start_date
  end
end
