class AddCounterCacheColumns < ActiveRecord::Migration[8.0]
  def up
    # Counter cache 컬럼 추가
    add_column :tests, :registrations_count, :integer, default: 0, null: false
    add_column :courses, :registrations_count, :integer, default: 0, null: false

    # Counter cache 초기값 설정
    execute <<-SQL.squish
      UPDATE tests
      SET registrations_count = (
        SELECT COUNT(*)
        FROM test_registrations
        WHERE test_registrations.test_id = tests.id
      )
    SQL

    execute <<-SQL.squish
      UPDATE courses
      SET registrations_count = (
        SELECT COUNT(*)
        FROM course_registrations
        WHERE course_registrations.course_id = courses.id
      )
    SQL

    # Counter cache 컬럼에 인덱스 추가 (인기순 정렬용)
    add_index :tests, :registrations_count, name: 'idx_tests_registrations_count'
    add_index :courses, :registrations_count, name: 'idx_courses_registrations_count'

    # 인기순 + 날짜별 복합 정렬 최적화
    add_index :tests, [:registrations_count, :created_at], name: 'idx_tests_popularity_created'
    add_index :courses, [:registrations_count, :created_at], name: 'idx_courses_popularity_created'
  end

  def down
    remove_index :courses, name: 'idx_courses_popularity_created'
    remove_index :tests, name: 'idx_tests_popularity_created'
    remove_index :courses, name: 'idx_courses_registrations_count'
    remove_index :tests, name: 'idx_tests_registrations_count'

    remove_column :courses, :registrations_count
    remove_column :tests, :registrations_count
  end
end