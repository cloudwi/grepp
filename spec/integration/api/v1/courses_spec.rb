require 'swagger_helper'

RSpec.describe 'api/v1/courses', type: :request do
  path '/api/v1/courses' do
    get('수업 목록 조회') do
      tags 'Courses'
      description '수업 목록을 조회합니다. 페이지네이션, 검색, 정렬, 필터링을 지원합니다.'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      parameter name: :page, in: :query, type: :integer, description: '페이지 번호 (기본값: 1)', required: false, example: 1
      parameter name: :per_page, in: :query, type: :integer, description: '페이지당 항목 수 (기본값: 20, 최대: 100)', required: false, example: 20
      parameter name: :search, in: :query, type: :string, description: '수업 제목으로 검색', required: false, example: '프로그래밍'
      parameter name: :status, in: :query, type: :string, description: '상태별 필터링', required: false, enum: [ 'available', 'upcoming', 'past' ]
      parameter name: :sort, in: :query, type: :string, description: '정렬 기준 (created=생성일 기준(기본값), popular=인기순, start_date=시작일순)', required: false, enum: [ 'created', 'popular', 'start_date' ]

      response(200, '수업 목록 조회 성공') do
        context '기본 목록 조회' do
          before do
            # Create test user and get JWT token
            @user = User.create!(email: 'test@example.com', password: 'password123')
            token = @user.generate_jwt_token

            # Create test data
            @course1 = Course.create!(title: '웹 개발 수업', enrollment_start_date: 1.day.ago, enrollment_end_date: 1.day.from_now)
            @course2 = Course.create!(title: 'AI 기초 수업', enrollment_start_date: 1.day.from_now, enrollment_end_date: 3.days.from_now)
            @course3 = Course.create!(title: '데이터베이스 수업', enrollment_start_date: 2.days.ago, enrollment_end_date: 2.days.from_now)

            # Create some registrations for popularity testing
            CourseRegistration.create!(user: @user, course: @course1)

            header 'Authorization', "Bearer #{token}"
          end

          schema '$ref' => '#/components/schemas/CoursesListResponse'

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['status']).to eq('success')
            expect(data['message']).to eq('코스 목록 조회가 완료되었습니다.')
            expect(data['data']['courses']).to be_an(Array)
            expect(data['data']['courses'].length).to eq(3)

            courses = data['data']['courses']

            # Check course structure
            course = courses.first
            expect(course).to have_key('id')
            expect(course).to have_key('title')
            expect(course).to have_key('enrollment_start_date')
            expect(course).to have_key('enrollment_end_date')
            expect(course).to have_key('status')
            expect(course).to have_key('enrolled')
            expect(course).to have_key('enrollment_count')

            # Check enrollment status
            enrolled_courses = courses.select { |c| c['enrolled'] == true }
            expect(enrolled_courses.length).to eq(1)
          end
        end

        context '상태별 필터링' do
          let(:status) { 'available' }

          before do
            @user = User.create!(email: 'test@example.com', password: 'password123')
            token = @user.generate_jwt_token

            # Available course
            Course.create!(title: '현재 진행 수업', enrollment_start_date: 1.day.ago, enrollment_end_date: 1.day.from_now)

            # Past course
            Course.create!(title: '완료된 수업', enrollment_start_date: 3.days.ago, enrollment_end_date: 2.days.ago)

            # Upcoming course
            Course.create!(title: '예정된 수업', enrollment_start_date: 1.day.from_now, enrollment_end_date: 3.days.from_now)

            header 'Authorization', "Bearer #{token}"
          end

          run_test! do |response|
            data = JSON.parse(response.body)
            courses = data['data']['courses']

            expect(courses.length).to eq(1)
            expect(courses.all? { |c| c['status'] == 'available' }).to be true
          end
        end

        context '인기순 정렬' do
          let(:sort) { 'popular' }

          before do
            @user = User.create!(email: 'test@example.com', password: 'password123')
            @user2 = User.create!(email: 'test2@example.com', password: 'password123')
            @user3 = User.create!(email: 'test3@example.com', password: 'password123')
            token = @user.generate_jwt_token

            @course1 = Course.create!(title: '인기 수업', enrollment_start_date: 1.day.ago, enrollment_end_date: 1.day.from_now)
            @course2 = Course.create!(title: '일반 수업', enrollment_start_date: 1.day.ago, enrollment_end_date: 1.day.from_now)

            # Create more registrations for course1
            CourseRegistration.create!(user: @user, course: @course1)
            CourseRegistration.create!(user: @user2, course: @course1)
            CourseRegistration.create!(user: @user3, course: @course1)
            CourseRegistration.create!(user: @user, course: @course2)

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

  path '/api/v1/courses/{id}/enroll' do
    parameter name: 'id', in: :path, type: :string, description: '수업 ID'

    post('수업 수강 신청') do
      tags 'Courses'
      description '수업 수강 신청을 처리하고 결제 정보를 저장합니다.'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      parameter name: :enrollment_request, in: :body, schema: {
        type: :object,
        properties: {
          amount: {
            type: :integer,
            description: '결제 금액',
            example: 45000
          },
          payment_method: {
            type: :string,
            description: '결제 방법 (kakaopay, card, bank 등)',
            example: 'kakaopay'
          }
        },
        required: [ 'amount', 'payment_method' ]
      }

      response(201, '수업 수강 신청 성공') do
        let(:id) { @course.id }
        let(:enrollment_request) { { amount: 45000, payment_method: 'kakaopay' } }

        before do
          @user = User.create!(email: 'enroll_test@example.com', password: 'password123')
          @token = @user.generate_jwt_token

          @course = Course.create!(
            title: '프로그래밍 기초 수업',
            enrollment_start_date: 1.day.ago,
            enrollment_end_date: 1.day.from_now
          )

          header 'Authorization', "Bearer #{@token}"
        end

        schema type: :object,
          properties: {
            status: { type: :string, example: 'success' },
            message: { type: :string, example: '수업 수강 신청이 완료되었습니다.' },
            data: {
              type: :object,
              properties: {
                registration_id: { type: :integer, example: 1 },
                course_id: { type: :integer, example: 1 },
                course_title: { type: :string, example: '프로그래밍 기초 수업' },
                payment: {
                  type: :object,
                  properties: {
                    id: { type: :integer, example: 1 },
                    amount: { type: :integer, example: 45000 },
                    payment_method: { type: :string, example: 'paypal' },
                    status: { type: :string, example: 'completed' },
                    payment_time: { type: :string, example: '2024-09-26T12:00:00Z' }
                  }
                }
              }
            }
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq('success')
          expect(data['message']).to eq('수업 수강 신청이 완료되었습니다.')
          expect(data['data']['registration_id']).to be_present
          expect(data['data']['course_id']).to eq(@course.id)
          expect(data['data']['course_title']).to eq(@course.title)
          expect(data['data']['payment']['amount']).to eq(45000)
          expect(data['data']['payment']['payment_method']).to eq('paypal')
          expect(data['data']['payment']['status']).to eq('completed')

          expect(@user.course_registrations.count).to eq(1)
          expect(Payment.count).to eq(1)
          payment = Payment.first
          expect(payment.user).to eq(@user)
          expect(payment.payable).to eq(@user.course_registrations.first)
        end
      end

      response(422, '중복 신청 에러') do
        let(:id) { @course.id }
        let(:enrollment_request) { { amount: 45000, payment_method: 'kakaopay' } }

        before do
          @user = User.create!(email: 'duplicate_test@example.com', password: 'password123')
          @token = @user.generate_jwt_token
          @course = Course.create!(
            title: '중복 신청 테스트 수업',
            enrollment_start_date: 1.day.ago,
            enrollment_end_date: 1.day.from_now
          )

          @user.course_registrations.create!(course: @course)

          header 'Authorization', "Bearer #{@token}"
        end

        schema '$ref' => '#/components/schemas/ErrorResponse'

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq('error')
          expect(data['message']).to eq('이미 신청한 수업입니다.')
        end
      end

      response(404, '수업을 찾을 수 없음') do
        let(:id) { 999999 }
        let(:enrollment_request) { { amount: 45000, payment_method: 'kakaopay' } }

        before do
          @user = User.create!(email: 'notfound_test@example.com', password: 'password123')
          @token = @user.generate_jwt_token
          header 'Authorization', "Bearer #{@token}"
        end

        schema '$ref' => '#/components/schemas/ErrorResponse'

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq('error')
          expect(data['message']).to eq('수업을 찾을 수 없습니다.')
        end
      end

      response(401, '인증 실패') do
        let(:id) { 1 }
        let(:enrollment_request) { { amount: 45000, payment_method: 'kakaopay' } }

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
