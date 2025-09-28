require 'swagger_helper'

RSpec.describe 'api/v1/tests', type: :request do
  path '/api/v1/tests' do
    get('시험 목록 조회') do
      tags 'Tests'
      description '시험 목록을 조회합니다. 페이지네이션, 검색, 정렬, 필터링을 지원합니다.'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      parameter name: :page, in: :query, type: :integer, description: '페이지 번호 (기본값: 1)', required: false, example: 1
      parameter name: :per_page, in: :query, type: :integer, description: '페이지당 항목 수 (기본값: 20, 최대: 100)', required: false, example: 20
      parameter name: :search, in: :query, type: :string, description: '시험 제목으로 검색', required: false, example: '프로그래밍'
      parameter name: :sort, in: :query, type: :string, description: '정렬 기준', required: false, enum: [ 'created', 'popular', 'start_date' ], example: 'created'
      parameter name: :status, in: :query, type: :string, description: '상태별 필터링', required: false, enum: [ 'available', 'upcoming', 'past' ], example: 'available'

      response(200, '시험 목록 조회 성공') do
        before do
          # Create test user and get JWT token
          user = User.create!(email: 'test@example.com', password: 'password123')
          token = user.generate_jwt_token

          # Create some test data
          Test.create!(title: '프로그래밍 기초 시험', start_date: 1.day.ago, end_date: 1.day.from_now)
          Test.create!(title: '알고리즘 시험', start_date: 1.day.from_now, end_date: 3.days.from_now)
          Test.create!(title: '완료된 시험', start_date: 3.days.ago, end_date: 2.days.ago)

          header 'Authorization', "Bearer #{token}"
        end

        schema '$ref' => '#/components/schemas/TestsListResponse'

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq('success')
          expect(data['message']).to eq('시험 목록 조회가 완료되었습니다.')
          expect(data['data']['tests']).to be_an(Array)
          expect(data['data']['tests'].length).to eq(3)

          # Check test status logic
          tests = data['data']['tests']
          expect(tests.any? { |t| t['status'] == 'available' }).to be true
          expect(tests.any? { |t| t['status'] == 'upcoming' }).to be true
          expect(tests.any? { |t| t['status'] == 'past' }).to be true
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
