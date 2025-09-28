class Api::V1::CoursesController < ApplicationController
  before_action :authenticate_user!

  def index
    courses_data = build_courses_query
    render json: success_response("코스 목록 조회가 완료되었습니다.", courses_data)
  end

  private

  def build_courses_query
    courses_relation = build_courses_relation
    paginated_courses = apply_pagination(courses_relation)
    serialize_with_pagination(paginated_courses)
  end

  def build_courses_relation
    Course.left_joins(:course_registrations)
          .select(
            "courses.*",
            "COUNT(course_registrations.id) as enrollment_count"
          )
          .group("courses.id")
          .then { |relation| apply_search_filter(relation) }
          .then { |relation| apply_status_filter(relation) }
          .then { |relation| apply_sorting(relation) }
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
        status: calculate_course_status(course),
        enrolled: current_user_enrolled_in_course?(course.id),
        enrollment_count: course.attributes["enrollment_count"].to_i,
        created_at: course.created_at
      }
    end
  end

  def apply_pagination(relation)
    page = [ params[:page].to_i, 1 ].max
    per_page = [ (params[:per_page] || 20).to_i, 100 ].min

    relation.page(page).per(per_page)
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

  def apply_search_filter(relation)
    return relation if params[:search].blank?

    search_term = "%#{params[:search]}%"
    relation.where("courses.title LIKE ?", search_term)
  end

  def apply_status_filter(relation)
    return relation if params[:status].blank?

    current_time = Time.current
    case params[:status]
    when "available"
      relation.where("courses.enrollment_start_date <= ? AND courses.enrollment_end_date >= ?", current_time, current_time)
    when "upcoming"
      relation.where("courses.enrollment_start_date > ?", current_time)
    when "past"
      relation.where(courses: { enrollment_end_date: ...current_time })
    else
      relation
    end
  end

  def apply_sorting(relation)
    case params[:sort]
    when "popular"
      relation.order(enrollment_count: :desc)
    when "start_date"
      relation.order("courses.enrollment_start_date ASC")
    else
      relation.order("courses.created_at DESC")
    end
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

  def success_response(message, data = {})
    {
      status: "success",
      message: message,
      data: data
    }
  end
end
