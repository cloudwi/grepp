class Api::V1::TestsController < ApplicationController
  before_action :authenticate_user!, only: [ :apply ]
  def index
    tests = build_tests_query
    render json: success_response("시험 목록 조회가 완료되었습니다.", tests)
  end

  def apply
    test = Test.find(params[:id])

    existing_registration = current_user.test_registrations.find_by(test: test)
    if existing_registration
      return render json: error_response("이미 신청한 시험입니다."), status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      test_registration = current_user.test_registrations.create!(test: test)

      payment = Payment.create!(
        user: current_user,
        payable: test_registration,
        amount: application_params[:amount],
        payment_method: normalized_payment_method,
        status: "completed",
        payment_time: Time.current
      )

      render json: success_response(
        "시험 응시 신청이 완료되었습니다.",
        {
          registration_id: test_registration.id,
          test_id: test.id,
          test_title: test.title,
          payment: {
            id: payment.id,
            amount: payment.amount,
            payment_method: payment.payment_method,
            status: payment.status,
            payment_time: payment.payment_time
          }
        }
      ), status: :created
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: error_response("신청 처리 중 오류가 발생했습니다.", e.record.errors.full_messages), status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    render json: error_response("시험을 찾을 수 없습니다."), status: :not_found
  end

  private

  def build_tests_query
    tests_relation = build_tests_relation
    paginated_tests = apply_pagination(tests_relation)
    serialize_with_pagination(paginated_tests)
  end

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

  def serialize_with_pagination(paginated_tests)
    {
      tests: serialize_tests(paginated_tests),
      pagination: build_pagination_meta(paginated_tests)
    }
  end

  def serialize_tests(tests_relation)
    tests_relation.map do |test|
      {
        id: test.id,
        title: test.title,
        start_date: test.start_date,
        end_date: test.end_date,
        status: calculate_test_status(test),
        enrollment_count: test.attributes["enrollment_count"].to_i,
        created_at: test.created_at
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

  def calculate_test_status(test)
    current_time = Time.current

    if current_time < test.start_date
      "upcoming"
    elsif current_time >= test.start_date && current_time <= test.end_date
      "available"
    else
      "past"
    end
  end

  def application_params
    params.permit(:amount, :payment_method).tap do |p|
      p.require(:amount)
      p.require(:payment_method)
    end
  end

  def normalized_payment_method
    case application_params[:payment_method].downcase
    when "kakaopay", "kakao"
      "paypal"
    when "card", "credit"
      "credit_card"
    when "bank"
      "bank_transfer"
    else
      "paypal"
    end
  end

  def error_response(message, errors = [])
    {
      status: "error",
      message: message,
      errors: Array(errors)
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
