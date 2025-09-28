class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def up
    # ===========================================
    # 1. PAYMENTS 테이블 최적화
    # ===========================================

    # 결제 상태별 조회 최적화 (PaymentSearchService)
    add_index :payments, :status, name: 'idx_payments_status'

    # 결제 시간 범위 검색 최적화 (from/to 파라미터)
    add_index :payments, :payment_time, name: 'idx_payments_payment_time'

    # 사용자별 결제 내역 + 상태 복합 조회 최적화
    add_index :payments, [:user_id, :status], name: 'idx_payments_user_status'

    # 사용자별 결제 내역 + 시간순 정렬 최적화
    add_index :payments, [:user_id, :payment_time], name: 'idx_payments_user_time'

    # 결제 취소 시간 조회 최적화
    add_index :payments, :cancelled_at, name: 'idx_payments_cancelled_at'

    # ===========================================
    # 2. TESTS 테이블 최적화
    # ===========================================

    # 시험 상태 필터링 최적화 (available, upcoming, past)
    # 현재 시간과 start_date, end_date 비교가 빈번함
    add_index :tests, [:start_date, :end_date, :created_at], name: 'idx_tests_status_created'

    # 인기순 정렬 + 상태 필터링 복합 최적화
    add_index :tests, [:start_date, :end_date, :title], name: 'idx_tests_status_title'

    # 가격 범위 검색 최적화
    add_index :tests, :price, name: 'idx_tests_price'

    # PostgreSQL 전문 검색 인덱스 (제목 검색 최적화)
    execute <<-SQL
      CREATE INDEX idx_tests_title_search ON tests
      USING gin(to_tsvector('simple', coalesce(title, '')));
    SQL

    # ===========================================
    # 3. COURSES 테이블 최적화
    # ===========================================

    # 수업 상태 필터링 최적화 (available, upcoming, past)
    add_index :courses, [:enrollment_start_date, :enrollment_end_date, :created_at],
              name: 'idx_courses_status_created'

    # 인기순 정렬 + 상태 필터링 복합 최적화
    add_index :courses, [:enrollment_start_date, :enrollment_end_date, :title],
              name: 'idx_courses_status_title'

    # 가격 범위 검색 최적화
    add_index :courses, :price, name: 'idx_courses_price'

    # PostgreSQL 전문 검색 인덱스 (제목 검색 최적화)
    execute <<-SQL
      CREATE INDEX idx_courses_title_search ON courses
      USING gin(to_tsvector('simple', coalesce(title, '')));
    SQL

    # ===========================================
    # 4. REGISTRATIONS 테이블 최적화
    # ===========================================

    # 사용자별 시험 신청 내역 + 완료 상태 복합 조회
    add_index :test_registrations, [:user_id, :completed_at], name: 'idx_test_reg_user_completed'

    # 시험별 신청자 수 집계 최적화 (enrollment_count 계산용)
    add_index :test_registrations, [:test_id, :created_at], name: 'idx_test_reg_test_created'

    # 사용자별 수업 신청 내역 + 완료 상태 복합 조회
    add_index :course_registrations, [:user_id, :completed_at], name: 'idx_course_reg_user_completed'

    # 수업별 신청자 수 집계 최적화 (enrollment_count 계산용)
    add_index :course_registrations, [:course_id, :created_at], name: 'idx_course_reg_course_created'

    # 중복 신청 확인 최적화 (unique constraint는 이미 있지만 성능상 별도 인덱스)
    add_index :test_registrations, [:user_id, :test_id], name: 'idx_test_reg_user_test', unique: true
    add_index :course_registrations, [:user_id, :course_id], name: 'idx_course_reg_user_course', unique: true

    # ===========================================
    # 5. 파셜 인덱스 (조건부 인덱스) 최적화
    # ===========================================

    # 완료되지 않은 시험만 인덱싱 (대부분의 조회가 미완료 상태)
    execute <<-SQL
      CREATE INDEX idx_test_reg_pending ON test_registrations (user_id, test_id)
      WHERE completed_at IS NULL;
    SQL

    # 완료되지 않은 수업만 인덱싱
    execute <<-SQL
      CREATE INDEX idx_course_reg_pending ON course_registrations (user_id, course_id)
      WHERE completed_at IS NULL;
    SQL

    # 활성 결제만 인덱싱 (취소되지 않은 결제)
    execute <<-SQL
      CREATE INDEX idx_payments_active ON payments (user_id, created_at)
      WHERE status IN ('completed', 'pending');
    SQL
  end

  def down
    # 인덱스 제거 (역순으로)
    execute "DROP INDEX IF EXISTS idx_payments_active"
    execute "DROP INDEX IF EXISTS idx_course_reg_pending"
    execute "DROP INDEX IF EXISTS idx_test_reg_pending"

    remove_index :course_registrations, name: 'idx_course_reg_user_course'
    remove_index :test_registrations, name: 'idx_test_reg_user_test'
    remove_index :course_registrations, name: 'idx_course_reg_course_created'
    remove_index :test_registrations, name: 'idx_test_reg_test_created'
    remove_index :course_registrations, name: 'idx_course_reg_user_completed'
    remove_index :test_registrations, name: 'idx_test_reg_user_completed'

    execute "DROP INDEX IF EXISTS idx_courses_title_search"
    remove_index :courses, name: 'idx_courses_price'
    remove_index :courses, name: 'idx_courses_status_title'
    remove_index :courses, name: 'idx_courses_status_created'

    execute "DROP INDEX IF EXISTS idx_tests_title_search"
    remove_index :tests, name: 'idx_tests_price'
    remove_index :tests, name: 'idx_tests_status_title'
    remove_index :tests, name: 'idx_tests_status_created'

    remove_index :payments, name: 'idx_payments_cancelled_at'
    remove_index :payments, name: 'idx_payments_user_time'
    remove_index :payments, name: 'idx_payments_user_status'
    remove_index :payments, name: 'idx_payments_payment_time'
    remove_index :payments, name: 'idx_payments_status'
  end
end