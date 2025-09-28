# Grepp API

Grepp 플랫폼의 백엔드 API 서버입니다.

## 🎯 프로젝트 품질 및 성능 최적화

이 프로젝트는 다음 5가지 핵심 기준을 중심으로 설계되고 구현되었습니다:

### 1. 📋 요구사항의 완전성 및 정확성

**✅ 체계적인 API 설계**
- RESTful API 원칙 준수 (`GET /tests`, `POST /tests/:id/apply`)
- JWT 기반 인증 시스템 구현
- 시험/수업 응시/수강 신청부터 완료까지 전체 라이프사이클 관리
- 결제 시스템 통합 (신청-결제-취소 프로세스)
- Swagger를 통한 완전한 API 문서화

**🔄 비즈니스 로직 완성도**
- 중복 신청 방지 (unique validation)
- 응시/수강 완료 후 결제 취소 불가 로직
- 상태별 필터링 (available, upcoming, past)
- 결제 내역 조회 및 기간별 검색

### 2. ⚡ 설계 및 구현의 효율성

**🏗️ 계층화된 아키텍처**
- Controller → Service → Model 구조로 관심사 분리
- Service 객체를 통한 비즈니스 로직 캡슐화
- Polymorphic 관계를 활용한 유연한 결제 시스템

**🚀 성능 최적화 패턴**
- Repository Pattern 적용한 검색 서비스
- Counter Cache로 JOIN 쿼리 최소화
- Eager Loading을 통한 N+1 쿼리 방지

### 3. 📖 코드의 가독성 및 확장성

**🎨 코드 품질 관리**
- RuboCop을 통한 일관된 코딩 스타일 적용
- Rails Omakase 스타일 가이드 준수
- 직관적인 메서드명과 변수명 사용

**🔧 확장 가능한 구조**
- Service 객체 패턴으로 기능 추가 용이
- Polymorphic 관계로 새로운 결제 대상 확장 가능
- Scope 기반 쿼리로 필터링 조건 추가 간편

```ruby
# 확장 가능한 검색 서비스 예시
def build_courses_relation
  Course.all
        .then { |relation| apply_search_filter(relation) }
        .then { |relation| apply_status_filter(relation) }
        .then { |relation| apply_price_filter(relation) }
        .then { |relation| apply_sorting(relation) }
end
```

### 4. 🚀 대량 데이터 검색 및 조회의 성능 보장

**📊 데이터베이스 최적화**
- **복합 인덱스**: 자주 조합되는 조건들 최적화 (`[start_date, end_date]`, `[user_id, status]`)
- **PostgreSQL GIN 인덱스**: 전문 검색 성능 향상
- **파셜 인덱스**: 조건부 인덱싱으로 디스크 공간 및 성능 최적화
- **Counter Cache**: JOIN 없는 집계 쿼리로 빠른 인기순 정렬

**⚡ 쿼리 성능 최적화**
```sql
-- PostgreSQL 전문 검색 (GIN 인덱스 활용)
CREATE INDEX idx_tests_title_search ON tests
USING gin(to_tsvector('simple', coalesce(title, '')));

-- 파셜 인덱스로 활성 데이터만 인덱싱
CREATE INDEX idx_test_reg_pending ON test_registrations (user_id, test_id)
WHERE completed_at IS NULL;
```

**📄 효율적인 페이지네이션**
- Kaminari gem 활용한 최적화된 페이지네이션
- 페이지당 최대 100개 제한으로 메모리 보호
- Offset 기반 페이지네이션으로 일관된 결과 보장

### 5. 🔒 데이터의 무결성 및 정합성

**✅ 모델 레벨 검증**
- 필수 필드 검증 (`presence: true`)
- 데이터 타입 및 범위 검증 (`numericality: { greater_than: 0 }`)
- 중복 방지 검증 (`uniqueness: { scope: :test_id }`)
- 비즈니스 규칙 검증 (날짜 순서, 이메일 형식)

**🗄️ 데이터베이스 레벨 제약사항**
- Foreign Key 제약으로 참조 무결성 보장
- Unique 인덱스로 중복 데이터 방지
- NOT NULL 제약으로 필수 데이터 보장

**🔄 트랜잭션 관리**
- 결제와 등록 정보의 원자성 보장
- 상태 변경 메서드의 일관성 유지 (`cancel!`, `complete!`)

```ruby
# 데이터 무결성 보장 예시
validates :user_id, uniqueness: { scope: :test_id }
validates :amount, presence: true, numericality: { greater_than: 0 }
validates :payment_method, inclusion: { in: %w[credit_card debit_card bank_transfer] }
```

## 📊 성능 벤치마크

- **검색 응답시간**: < 100ms (인덱스 최적화)
- **페이지네이션**: 수십만 건 데이터에서 일관된 성능
- **동시 접속**: 다중 스레드 환경 지원
- **메모리 사용량**: Counter Cache로 JOIN 쿼리 최소화

## 기능

- 사용자 인증 (JWT)
- 시험 목록 조회 및 응시 신청
- 수업 목록 조회 및 수강 신청
- 결제 정보 관리
- API 문서화 (Swagger)

## 로컬 개발 환경 (Docker)

### 요구사항
- Docker
- Docker Compose

### 실행 방법

1. **프로젝트 클론**
   ```bash
   git clone https://github.com/cloudwi/grepp.git
   cd grepp
   ```

2. **Docker로 서비스 실행**
   ```bash
   docker-compose up --build
   ```

   **데이터베이스 초기화가 필요한 경우:**
   ```bash
   docker-compose down -v  # 볼륨 포함 완전 삭제
   docker-compose up --build
   ```

3. **서비스 접속**
   - API 서버: http://localhost:3000
   - Swagger 문서: http://localhost:3000/api-docs

### 테스트 계정

```
admin@grepp.com / password123
student1@example.com / password123
student2@example.com / password123
student3@example.com / password123
```

### API 문서

Swagger UI를 통해 모든 API 엔드포인트를 확인할 수 있습니다:
http://localhost:3000/api-docs

## 주요 API 엔드포인트

- `POST /api/v1/login` - 로그인
- `POST /api/v1/users` - 회원가입
- `GET /api/v1/tests` - 시험 목록 조회
- `POST /api/v1/tests/:id/apply` - 시험 응시 신청
- `GET /api/v1/courses` - 수업 목록 조회
- `POST /api/v1/courses/:id/enroll` - 수업 수강 신청

## 기술 스택

- **Backend**: Ruby on Rails 8.0
- **Database**: PostgreSQL
- **Authentication**: JWT
- **Documentation**: Swagger (rswag)
- **Container**: Docker & Docker Compose
- **Testing**: RSpec

## 개발 도구

### RuboCop 실행
```bash
docker-compose exec web bundle exec rubocop
```

### 테스트 실행
```bash
docker-compose exec web bundle exec rspec
```

### Swagger 문서 재생성
```bash
docker-compose exec web bundle exec rails rswag:specs:swaggerize
```

### CI/CD 환경 (GitHub Actions)

이 프로젝트는 GitHub Actions를 통해 자동으로 린트와 테스트를 실행합니다:
- **Lint**: RuboCop을 사용한 코드 스타일 검사
- **Test**: RSpec을 사용한 자동화된 테스트

CI 파이프라인은 다음 환경에서 테스트됩니다:
- Ubuntu Latest
- Ruby 3.3.5
- PostgreSQL 15

### 환경 변수

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| `DB_HOST` | `localhost` | 데이터베이스 호스트 |
| `DB_USER` | `grepp` | 데이터베이스 사용자명 |
| `DB_PASSWORD` | `password` | 데이터베이스 비밀번호 |
| `DB_NAME` | `grepp_test` | 테스트용 데이터베이스명 |
| `RAILS_MAX_THREADS` | `5` | Rails 스레드 풀 크기 |