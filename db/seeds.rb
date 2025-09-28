# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

Rails.logger.debug "🌱 시딩 시작..."

# 기본 사용자 생성
Rails.logger.debug "👤 사용자 생성 중..."
admin_user = User.find_or_create_by!(email: 'admin@grepp.com') do |user|
  user.password = 'password123'
end

student1 = User.find_or_create_by!(email: 'student1@example.com') do |user|
  user.password = 'password123'
end

student2 = User.find_or_create_by!(email: 'student2@example.com') do |user|
  user.password = 'password123'
end

student3 = User.find_or_create_by!(email: 'student3@example.com') do |user|
  user.password = 'password123'
end

# 시험 데이터 생성
Rails.logger.debug "📝 시험 생성 중..."

# 현재 응시 가능한 시험들
Test.find_or_create_by!(title: '프로그래밍 기초 시험') do |test|
  test.start_date = 2.days.ago
  test.end_date = 5.days.from_now
  test.price = 35000
end

Test.find_or_create_by!(title: '알고리즘 실전 시험') do |test|
  test.start_date = 1.day.ago
  test.end_date = 3.days.from_now
  test.price = 45000
end

Test.find_or_create_by!(title: '데이터베이스 설계 시험') do |test|
  test.start_date = 1.hour.ago
  test.end_date = 7.days.from_now
  test.price = 50000
end

# 예정된 시험들
Test.find_or_create_by!(title: 'React 개발 시험') do |test|
  test.start_date = 3.days.from_now
  test.end_date = 10.days.from_now
  test.price = 40000
end

Test.find_or_create_by!(title: 'Node.js 백엔드 시험') do |test|
  test.start_date = 5.days.from_now
  test.end_date = 12.days.from_now
  test.price = 45000
end

# 완료된 시험들
Test.find_or_create_by!(title: 'HTML/CSS 기초 시험') do |test|
  test.start_date = 10.days.ago
  test.end_date = 5.days.ago
  test.price = 25000
end

Test.find_or_create_by!(title: 'JavaScript 기초 시험') do |test|
  test.start_date = 15.days.ago
  test.end_date = 8.days.ago
  test.price = 30000
end

# 수업 데이터 생성
Rails.logger.debug "🎓 수업 생성 중..."

# 현재 수강 신청 가능한 수업들
Course.find_or_create_by!(title: '풀스택 웹 개발 부트캠프') do |course|
  course.enrollment_start_date = 3.days.ago
  course.enrollment_end_date = 7.days.from_now
  course.price = 299000
end

Course.find_or_create_by!(title: 'AI/ML 기초 과정') do |course|
  course.enrollment_start_date = 1.day.ago
  course.enrollment_end_date = 10.days.from_now
  course.price = 399000
end

Course.find_or_create_by!(title: '데이터 사이언스 실무') do |course|
  course.enrollment_start_date = 2.hours.ago
  course.enrollment_end_date = 5.days.from_now
  course.price = 599000
end

# 예정된 수업들
Course.find_or_create_by!(title: '클라우드 아키텍처 설계') do |course|
  course.enrollment_start_date = 2.days.from_now
  course.enrollment_end_date = 14.days.from_now
  course.price = 499000
end

Course.find_or_create_by!(title: '모바일 앱 개발 (Flutter)') do |course|
  course.enrollment_start_date = 4.days.from_now
  course.enrollment_end_date = 18.days.from_now
  course.price = 449000
end

# 완료된 수업들
Course.find_or_create_by!(title: 'Git 버전 관리') do |course|
  course.enrollment_start_date = 20.days.ago
  course.enrollment_end_date = 10.days.ago
  course.price = 149000
end

Course.find_or_create_by!(title: 'Linux 시스템 관리') do |course|
  course.enrollment_start_date = 25.days.ago
  course.enrollment_end_date = 15.days.ago
  course.price = 199000
end

# 등록 데이터 생성 (인기도를 위해)
Rails.logger.debug "📋 등록 데이터 생성 중..."

# 시험 등록
tests = Test.all
popular_test = Test.find_by(title: '프로그래밍 기초 시험')
medium_test = Test.find_by(title: '알고리즘 실전 시험')

# 인기 있는 시험에 더 많은 등록자
[ student1, student2, student3 ].each do |user|
  TestRegistration.find_or_create_by!(user: user, test: popular_test)
end

# 중간 인기 시험에 일부 등록자
[ student1, student2 ].each do |user|
  TestRegistration.find_or_create_by!(user: user, test: medium_test)
end

# 수업 등록
popular_course = Course.find_by(title: '풀스택 웹 개발 부트캠프')
medium_course = Course.find_by(title: 'AI/ML 기초 과정')

# 인기 있는 수업에 더 많은 등록자
[ student1, student2, student3 ].each do |user|
  CourseRegistration.find_or_create_by!(user: user, course: popular_course)
end

# 중간 인기 수업에 일부 등록자
[ student2, student3 ].each do |user|
  CourseRegistration.find_or_create_by!(user: user, course: medium_course)
end

Rails.logger.debug "✅ 시딩 완료!"
Rails.logger.debug ""
Rails.logger.debug "📊 생성된 데이터:"
Rails.logger.debug { "   사용자: #{User.count}명" }
Rails.logger.debug { "   시험: #{Test.count}개" }
Rails.logger.debug { "   수업: #{Course.count}개" }
Rails.logger.debug { "   시험 등록: #{TestRegistration.count}개" }
Rails.logger.debug { "   수업 등록: #{CourseRegistration.count}개" }
Rails.logger.debug ""
Rails.logger.debug "🔑 테스트 계정:"
Rails.logger.debug "   admin@grepp.com / password123"
Rails.logger.debug "   student1@example.com / password123"
Rails.logger.debug "   student2@example.com / password123"
Rails.logger.debug "   student3@example.com / password123"
