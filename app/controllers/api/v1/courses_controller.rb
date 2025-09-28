class Api::V1::CoursesController < ApplicationController
  before_action :authenticate_user!

  def index
    courses_data = build_courses_query
    render json: success_response("코스 목록 조회가 완료되었습니다.", courses_data)
  end

  private

  def build_courses_query
    combined_courses = []
    tests = Test.includes(:test_registrations)
    tests = search_courses(tests, "test") if params[:search].present?
    tests = filter_by_status(tests, "test") if params[:status].present?
    tests = sort_courses(tests, "test")

    tests.each do |test|
      combined_courses << {
        id: "test_#{test.id}",
        type: "test",
        title: test.title,
        start_date: test.start_date,
        end_date: test.end_date,
        status: determine_test_status(test),
        enrolled: current_user_enrolled_in_test?(test.id),
        enrollment_count: test.test_registrations.count,
        created_at: test.created_at
      }
    end

    courses = Course.includes(:course_registrations)
    courses = search_courses(courses, "course") if params[:search].present?
    courses = filter_by_status(courses, "course") if params[:status].present?
    courses = sort_courses(courses, "course")

    courses.each do |course|
      combined_courses << {
        id: "course_#{course.id}",
        type: "course",
        title: course.title,
        start_date: course.enrollment_start_date,
        end_date: course.enrollment_end_date,
        status: determine_course_status(course),
        enrolled: current_user_enrolled_in_course?(course.id),
        enrollment_count: course.course_registrations.count,
        created_at: course.created_at
      }
    end

    sorted_courses = case params[:sort]
    when "popular"
      combined_courses.sort_by { |c| -c[:enrollment_count] }
    else
      combined_courses.sort_by { |c| -c[:created_at].to_i }
    end

    apply_pagination_to_array(sorted_courses)
  end

  def search_courses(query, type)
    return query if params[:search].blank?

    search_term = "%#{params[:search]}%"
    query.where("title LIKE ?", search_term)
  end

  def filter_by_status(query, type)
    return query unless params[:status] == "available"

    case type
    when "test"
      query.available
    when "course"
      query.enrollment_open
    end
  end

  def sort_courses(query, type)
    case params[:sort]
    when "popular"
      case type
      when "test"
        query.joins(:test_registrations)
             .group("tests.id")
             .order("COUNT(test_registrations.id) DESC")
      when "course"
        query.joins(:course_registrations)
             .group("courses.id")
             .order("COUNT(course_registrations.id) DESC")
      end
    else
      query.order(created_at: :desc)
    end
  end

  def determine_test_status(test)
    current_time = Time.current
    if test.end_date < current_time
      "past"
    elsif test.start_date <= current_time && test.end_date >= current_time
      "available"
    else
      "upcoming"
    end
  end

  def determine_course_status(course)
    current_time = Time.current
    if course.enrollment_end_date < current_time
      "past"
    elsif course.enrollment_start_date <= current_time && course.enrollment_end_date >= current_time
      "available"
    else
      "upcoming"
    end
  end

  def current_user_enrolled_in_test?(test_id)
    current_user.test_registrations.exists?(test_id: test_id)
  end

  def current_user_enrolled_in_course?(course_id)
    current_user.course_registrations.exists?(course_id: course_id)
  end

  def apply_pagination_to_array(array)
    page = [ params[:page].to_i, 1 ].max
    per_page = [ (params[:per_page] || 20).to_i, 100 ].min

    total_count = array.size
    total_pages = (total_count.to_f / per_page).ceil
    offset = (page - 1) * per_page

    paginated_items = array[offset, per_page] || []

    {
      courses: paginated_items,
      pagination: {
        current_page: page,
        total_pages: total_pages,
        total_count: total_count,
        per_page: per_page,
        has_next_page: page < total_pages,
        has_prev_page: page > 1
      }
    }
  end

  def success_response(message, data = {})
    {
      status: "success",
      message: message,
      data: data
    }
  end
end
