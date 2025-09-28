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