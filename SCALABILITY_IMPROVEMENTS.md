# 확장성 개선 방안 (100만+ 데이터 대응)

## 1. 데이터베이스 최적화

### 인덱스 추가
```sql
-- 상태별 필터링 최적화
CREATE INDEX idx_tests_status_dates ON tests (start_date, end_date);
CREATE INDEX idx_courses_enrollment_dates ON courses (enrollment_start_date, enrollment_end_date);

-- 검색 최적화 (PostgreSQL 전문 검색)
CREATE INDEX idx_tests_title_search ON tests USING gin(to_tsvector('english', title));
CREATE INDEX idx_courses_title_search ON courses USING gin(to_tsvector('english', title));

-- 복합 인덱스로 정렬 + 필터링 최적화
CREATE INDEX idx_tests_created_status ON tests (created_at, start_date, end_date);
CREATE INDEX idx_courses_created_status ON courses (created_at, enrollment_start_date, enrollment_end_date);
```

### Counter Cache 도입
```ruby
# app/models/test.rb
class Test < ApplicationRecord
  has_many :test_registrations, dependent: :destroy
  # enrollment_count 컬럼 추가하여 실시간 COUNT 제거
end

# 마이그레이션
add_column :tests, :enrollment_count, :integer, default: 0
add_column :courses, :enrollment_count, :integer, default: 0
```

## 2. 쿼리 최적화

### Cursor 기반 페이지네이션
```ruby
# OFFSET 대신 cursor 사용
def paginate_by_cursor(relation, cursor = nil, limit = 20)
  if cursor
    relation.where('id > ?', cursor).limit(limit)
  else
    relation.limit(limit)
  end
end
```

### 검색 최적화
```ruby
# PostgreSQL 전문 검색 사용
def search_by_title(relation, query)
  return relation if query.blank?

  relation.where(
    "to_tsvector('english', title) @@ plainto_tsquery('english', ?)",
    query
  )
end
```

## 3. 캐싱 전략

### Redis 캐싱 도입
```ruby
# 인기 있는 검색 결과 캐싱
def cached_search_results(params)
  cache_key = "search_#{params.to_query}"
  Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
    perform_search(params)
  end
end
```

### 데이터베이스 레벨 캐싱
```ruby
# 집계 데이터 사전 계산
class EnrollmentCountCache
  def self.update_for_test(test_id)
    count = TestRegistration.where(test_id: test_id).count
    Test.where(id: test_id).update_all(enrollment_count: count)
  end
end
```

## 4. 아키텍처 개선

### 비동기 처리
```ruby
# 무거운 작업을 백그라운드로 이동
class UpdateEnrollmentCountJob < ApplicationJob
  def perform(test_id)
    EnrollmentCountCache.update_for_test(test_id)
  end
end
```

### 데이터베이스 분할
```sql
-- 날짜 기반 파티셔닝 (PostgreSQL)
CREATE TABLE tests (
  id SERIAL,
  title VARCHAR,
  start_date DATE,
  -- ...
) PARTITION BY RANGE (start_date);

CREATE TABLE tests_2024 PARTITION OF tests
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

## 5. 모니터링 및 성능 측정

### 성능 메트릭 수집
```ruby
# 쿼리 성능 모니터링
class PerformanceMonitor
  def self.track_query(operation, &block)
    start_time = Time.current
    result = yield
    duration = Time.current - start_time

    Rails.logger.info "#{operation} completed in #{duration}ms"
    result
  end
end
```

### 데이터베이스 커넥션 풀링
```yml
# database.yml
production:
  pool: 25
  timeout: 5000
  checkout_timeout: 5
```

## 예상 성능 개선 효과

| 항목 | 현재 (100만 건) | 개선 후 |
|------|----------------|---------|
| 목록 조회 | 5-10초 | 100-200ms |
| 검색 쿼리 | 10-20초 | 50-100ms |
| 페이지네이션 | 선형 증가 | 일정 시간 |
| 집계 연산 | 매번 계산 | 사전 계산됨 |

## 단계별 적용 우선순위

1. **긴급**: 인덱스 추가, Counter Cache
2. **중요**: Cursor 페이지네이션, 캐싱
3. **장기**: 데이터베이스 분할, 비동기 처리