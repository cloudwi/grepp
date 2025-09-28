class CourseSearchService
  def initialize(params, current_user)
    @params = params
    @current_user = current_user
  end

  def call
    courses_relation = build_courses_relation
    paginated_courses = apply_pagination(courses_relation)
    serialize_with_pagination(paginated_courses)
  end

  private

  attr_reader :params, :current_user

  def build_courses_relation
    Course.all
          .then { |relation| apply_search_filter(relation) }
          .then { |relation| apply_status_filter(relation) }
          .then { |relation| apply_price_filter(relation) }
          .then { |relation| apply_sorting(relation) }
  end

  def apply_pagination(relation)
    page = [params[:page].to_i, 1].max
    per_page = [(params[:per_page] || 20).to_i, 100].min
    relation.page(page).per(per_page)
  end

  def serialize_with_pagination(paginated_courses)
    {
      courses: serialize_courses(paginated_courses),
      pagination: build_pagination_meta(paginated_courses)
    }
  end

  def serialize_courses(courses_relation)
    courses_relation.map do |course|
      {
        id: course.id,
        title: course.title,
        enrollment_start_date: course.enrollment_start_date,
        enrollment_end_date: course.enrollment_end_date,
        price: course.price,
        status: calculate_course_status(course),
        enrolled: current_user_enrolled_in_course?(course.id),
        enrollment_count: course.registrations_count,
        created_at: course.created_at
      }
    end
  end

  def apply_search_filter(relation)
    return relation if params[:search].blank?

    relation.search_by_title(params[:search])
  end

  def apply_status_filter(relation)
    return relation if params[:status].blank?

    case params[:status]
    when "available"
      relation.available
    when "upcoming"
      relation.upcoming
    when "past"
      relation.past
    else
      relation
    end
  end

  def apply_sorting(relation)
    case params[:sort]
    when "popular"
      relation.popular
    when "start_date"
      relation.by_start_date
    else
      relation.recent
    end
  end

  def apply_price_filter(relation)
    return relation unless params[:min_price].present? || params[:max_price].present?

    relation.price_between(params[:min_price], params[:max_price])
  end

  def calculate_course_status(course)
    current_time = Time.current
    if course.enrollment_end_date < current_time
      "past"
    elsif course.enrollment_start_date <= current_time && course.enrollment_end_date >= current_time
      "available"
    else
      "upcoming"
    end
  end

  def current_user_enrolled_in_course?(course_id)
    current_user.course_registrations.exists?(course_id: course_id)
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
