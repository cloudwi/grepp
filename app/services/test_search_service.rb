class TestSearchService
  def initialize(params)
    @params = params
  end

  def call
    tests_relation = build_tests_relation
    paginated_tests = apply_pagination(tests_relation)
    serialize_with_pagination(paginated_tests)
  end

  private

  attr_reader :params

  def build_tests_relation
    Test.left_joins(:test_registrations)
        .select(
          "tests.*",
          "COUNT(test_registrations.id) as enrollment_count"
        )
        .group("tests.id")
        .then { |relation| apply_search_filter(relation) }
        .then { |relation| apply_status_filter(relation) }
        .then { |relation| apply_sorting(relation) }
  end

  def apply_pagination(relation)
    page = [params[:page].to_i, 1].max
    per_page = [(params[:per_page] || 20).to_i, 100].min
    relation.page(page).per(per_page)
  end

  def serialize_with_pagination(paginated_tests)
    {
      tests: serialize_tests(paginated_tests),
      pagination: build_pagination_meta(paginated_tests)
    }
  end

  def serialize_tests(tests_relation)
    current_time = Time.current
    tests_relation.map do |test|
      {
        id: test.id,
        title: test.title,
        start_date: test.start_date,
        end_date: test.end_date,
        price: test.price,
        status: calculate_test_status_optimized(test, current_time),
        enrollment_count: test.attributes["enrollment_count"].to_i,
        created_at: test.created_at
      }
    end
  end

  def apply_search_filter(relation)
    return relation if params[:search].blank?

    search_term = "%#{params[:search]}%"
    relation.where("tests.title LIKE ?", search_term)
  end

  def apply_status_filter(relation)
    return relation if params[:status].blank?

    current_time = Time.current
    case params[:status]
    when "available"
      relation.where("tests.start_date <= ? AND tests.end_date >= ?", current_time, current_time)
    when "upcoming"
      relation.where("tests.start_date > ?", current_time)
    when "past"
      relation.where(tests: { end_date: ...current_time })
    else
      relation
    end
  end

  def apply_sorting(relation)
    case params[:sort]
    when "popular"
      relation.order(enrollment_count: :desc)
    when "start_date"
      relation.order("tests.start_date ASC")
    else
      relation.order("tests.created_at DESC")
    end
  end

  def calculate_test_status_optimized(test, current_time)
    if current_time < test.start_date
      "upcoming"
    elsif current_time >= test.start_date && current_time <= test.end_date
      "available"
    else
      "past"
    end
  end

  def build_pagination_meta(paginated_relation)
    {
      current_page: paginated_relation.current_page,
      total_pages: paginated_relation.total_pages,
      total_count: paginated_relation.total_count,
      per_page: paginated_relation.limit_value,
      has_next_page: !paginated_relation.last_page?,
      has_prev_page: !paginated_relation.first_page?
    }
  end
end
