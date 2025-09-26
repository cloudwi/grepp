class AddIndexesToTestsAndCourses < ActiveRecord::Migration[8.0]
  def change
    # Tests 테이블 인덱스
    add_index :tests, :title                    # 검색용
    add_index :tests, :start_date               # 정렬 및 상태 필터용
    add_index :tests, :end_date                 # 상태 필터용
    add_index :tests, :created_at               # 기본 정렬용
    add_index :tests, [:start_date, :end_date]  # 복합 인덱스 - available 상태 조회용

    # Courses 테이블 인덱스
    add_index :courses, :title                                            # 검색용
    add_index :courses, :enrollment_start_date                            # 정렬 및 상태 필터용
    add_index :courses, :enrollment_end_date                              # 상태 필터용
    add_index :courses, :created_at                                       # 기본 정렬용
    add_index :courses, [:enrollment_start_date, :enrollment_end_date]    # 복합 인덱스 - available 상태 조회용

    # Registration 테이블 인덱스 (COUNT 쿼리 성능 향상)
    add_index :test_registrations, :test_id     # 인기순 정렬용
    add_index :course_registrations, :course_id # 인기순 정렬용
  end
end
