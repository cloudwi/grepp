require 'swagger_helper'

RSpec.describe 'api/v1/courses', type: :request do
  path '/api/v1/courses' do
    get('코스 목록 조회 (시험 + 수업 통합)') do
      tags 'Courses'
      description '시험과 수업을 통합한 코스 목록을 조회합니다. 검색, 정렬, 필터링을 지원합니다.'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      parameter name: :page, in: :query, type: :integer, description: '페이지 번호 (기본값: 1)', required: false, example: 1
      parameter name: :per_page, in: :query, type: :integer, description: '페이지당 항목 수 (기본값: 20, 최대: 100)', required: false, example: 20
      parameter name: :search, in: :query, type: :string, description: '시험/수업 제목으로 검색', required: false, example: '프로그래밍'
      parameter name: :status, in: :query, type: :string, description: '상태별 필터링 (available만 지원)', required: false, enum: [ 'available' ]
      parameter name: :sort, in: :query, type: :string, description: '정렬 기준 (created=생성일 기준(기본값), popular=인기순)', required: false, enum: [ 'created', 'popular' ]

      response(200, '코스 목록 조회 성공') do
        context '기본 목록 조회' do
          before do
            # Create test user and get JWT token
            @user = User.create!(email: 'test@example.com', password: 'password123')
            token = @user.generate_jwt_token

            # Create test data
            @test1 = Test.create!(title: '프로그래밍 기초 시험', start_date: 1.day.ago, end_date: 1.day.from_now)
            @test2 = Test.create!(title: '알고리즘 시험', start_date: 1.day.from_now, end_date: 3.days.from_now)
            @course1 = Course.create!(title: '웹 개발 수업', enrollment_start_date: 1.day.ago, enrollment_end_date: 1.day.from_now)
            @course2 = Course.create!(title: 'AI 기초 수업', enrollment_start_date: 1.day.from_now, enrollment_end_date: 3.days.from_now)

            # Create some registrations for popularity testing
            TestRegistration.create!(user: @user, test: @test1)
            CourseRegistration.create!(user: @user, course: @course1)

            header 'Authorization', "Bearer #{token}"
          end

          schema '$ref' => '#/components/schemas/CoursesListResponse'

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['status']).to eq('success')
            expect(data['message']).to eq('코스 목록 조회가 완료되었습니다.')
            expect(data['data']['courses']).to be_an(Array)
            expect(data['data']['courses'].length).to eq(4)

            courses = data['data']['courses']

            # Check course structure
            course = courses.first
            expect(course).to have_key('id')
            expect(course).to have_key('type')
            expect(course).to have_key('title')
            expect(course).to have_key('start_date')
            expect(course).to have_key('end_date')
            expect(course).to have_key('status')
            expect(course).to have_key('enrolled')
            expect(course).to have_key('enrollment_count')

            # Check types
            expect(courses.select { |c| c['type'] == 'test' }.length).to eq(2)
            expect(courses.select { |c| c['type'] == 'course' }.length).to eq(2)

            # Check enrollment status
            enrolled_courses = courses.select { |c| c['enrolled'] == true }
            expect(enrolled_courses.length).to eq(2)
          end
        end

        context '상태별 필터링' do
          let(:status) { 'available' }

          before do
            @user = User.create!(email: 'test@example.com', password: 'password123')
            token = @user.generate_jwt_token

            # Available test and course
            Test.create!(title: '현재 진행 시험', start_date: 1.day.ago, end_date: 1.day.from_now)
            Course.create!(title: '현재 진행 수업', enrollment_start_date: 1.day.ago, enrollment_end_date: 1.day.from_now)

            # Past test and course
            Test.create!(title: '완료된 시험', start_date: 3.days.ago, end_date: 2.days.ago)
            Course.create!(title: '완료된 수업', enrollment_start_date: 3.days.ago, enrollment_end_date: 2.days.ago)

            header 'Authorization', "Bearer #{token}"
          end

          run_test! do |response|
            data = JSON.parse(response.body)
            courses = data['data']['courses']

            expect(courses.length).to eq(2)
            expect(courses.all? { |c| c['status'] == 'available' }).to be true
          end
        end

        context '인기순 정렬' do
          let(:sort) { 'popular' }

          before do
            @user = User.create!(email: 'test@example.com', password: 'password123')
            @user2 = User.create!(email: 'test2@example.com', password: 'password123')
            token = @user.generate_jwt_token

            @test1 = Test.create!(title: '인기 시험', start_date: 1.day.ago, end_date: 1.day.from_now)
            @test2 = Test.create!(title: '일반 시험', start_date: 1.day.ago, end_date: 1.day.from_now)

            # Create more registrations for test1
            TestRegistration.create!(user: @user, test: @test1)
            TestRegistration.create!(user: @user2, test: @test1)
            TestRegistration.create!(user: @user, test: @test2)

            header 'Authorization', "Bearer #{token}"
          end

          run_test! do |response|
            data = JSON.parse(response.body)
            courses = data['data']['courses']

            # First course should be more popular
            expect(courses.first['enrollment_count']).to be >= courses.last['enrollment_count']
          end
        end
      end

      response(401, '인증 실패') do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq('error')
          expect(data['message']).to eq('인증이 필요합니다.')
        end
      end
    end
  end
end
