require 'swagger_helper'

RSpec.describe 'api/v1/auth', type: :request do
  path '/api/v1/login' do
    post('로그인') do
      tags 'Authentication'
      description '사용자 로그인 및 JWT 토큰 발급'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :user, in: :body, schema: {
        '$ref' => '#/components/schemas/LoginRequest'
      }

      response(200, '로그인 성공') do
        let(:user) do
          {
            user: {
              email: 'test@example.com',
              password: 'password123'
            }
          }
        end

        before do
          User.create!(email: 'test@example.com', password: 'password123')
        end

        schema '$ref' => '#/components/schemas/LoginSuccessResponse'

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq('success')
          expect(data['message']).to eq('로그인이 완료되었습니다.')
          expect(data['data']['user']['email']).to eq('test@example.com')
          expect(data['data']['token']).to be_present
        end
      end

      response(401, '로그인 실패 - 잘못된 자격증명') do
        let(:user) do
          {
            user: {
              email: 'wrong@example.com',
              password: 'wrongpassword'
            }
          }
        end

        schema '$ref' => '#/components/schemas/ErrorResponse'

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq('error')
          expect(data['message']).to eq('이메일 또는 비밀번호가 올바르지 않습니다.')
          expect(data['errors']).to include('Invalid email or password')
        end
      end
    end
  end
end