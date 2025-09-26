class Api::V1::TestsController < ApplicationController
  before_action :authenticate_user!, only: [:show]

  def index
    tests = build_tests_query
    render json: success_response("시험 목록 조회가 완료되었습니다.", { tests: tests })
  end

  private

  def build_tests_query
    # 🔍 Rails Console Debug Hint:
    # tests_relation = build_tests_relation
    # puts tests_relation.to_sql  # 실제 실행될 SQL 확인
    # puts tests_relation.explain # 실행 계획 확인

    tests_relation = build_tests_relation
    # ⚡ SQL 실행 시점: 아래 .map이 호출될 때 실제 SQL이 실행됩니다
    serialize_tests(tests_relation)
  end

  def build_tests_relation
    # 🚀 Relation 구성 단계 (아직 SQL 실행되지 않음)
    # N+1 방지: LEFT JOIN으로 enrollment_count를 미리 계산
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

  def serialize_tests(tests_relation)
    # ⚡ SQL 실행 시점: .map이 레코드를 순회하면서 SQL이 실행됩니다
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

  def apply_search_filter(relation)
    return relation unless params[:search].present?

    search_term = "%#{params[:search]}%"
    relation.where("tests.title LIKE ?", search_term)
  end

  def apply_status_filter(relation)
    return relation unless params[:status].present?

    current_time = Time.current
    case params[:status]
    when "available"
      relation.where("tests.start_date <= ? AND tests.end_date >= ?", current_time, current_time)
    when "upcoming"
      relation.where("tests.start_date > ?", current_time)
    when "past"
      relation.where("tests.end_date < ?", current_time)
    else
      relation
    end
  end

  def apply_sorting(relation)
    case params[:sort]
    when "popular"
      relation.order("enrollment_count DESC")
    when "start_date"
      relation.order("tests.start_date ASC")
    else # 'created' or default
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

  def success_response(message, data = {})
    {
      status: "success",
      message: message,
      data: data
    }
  end
end