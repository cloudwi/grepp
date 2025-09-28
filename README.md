# Grepp API

Grepp 플랫폼의 백엔드 API 서버입니다.

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
   git clone <repository-url>
   cd grepp
   ```

2. **Docker로 서비스 실행**
   ```bash
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

## 네이티브 환경에서 실행 (Docker 없이)

### 요구사항
- Ruby 3.3.5
- PostgreSQL 15
- Bundler

### 설정 방법

1. **Ruby와 Bundler 설치**
   ```bash
   # rbenv 사용 예시
   rbenv install 3.3.5
   rbenv global 3.3.5
   gem install bundler
   ```

2. **PostgreSQL 설치 및 설정**
   ```bash
   # macOS (Homebrew)
   brew install postgresql@15
   brew services start postgresql@15

   # Ubuntu/Debian
   sudo apt update
   sudo apt install postgresql-15 postgresql-client-15
   sudo systemctl start postgresql
   ```

3. **데이터베이스 사용자 생성**
   ```sql
   sudo -u postgres psql
   CREATE USER grepp WITH PASSWORD 'password';
   CREATE DATABASE grepp_development OWNER grepp;
   CREATE DATABASE grepp_test OWNER grepp;
   ALTER USER grepp CREATEDB;
   \q
   ```

4. **의존성 설치**
   ```bash
   bundle install
   ```

5. **데이터베이스 설정**
   ```bash
   bundle exec rails db:create
   bundle exec rails db:migrate
   bundle exec rails db:seed
   ```

6. **서버 실행**
   ```bash
   bundle exec rails server
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