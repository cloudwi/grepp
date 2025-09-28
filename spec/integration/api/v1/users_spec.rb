require 'swagger_helper'

RSpec.describe 'api/v1/users', type: :request do
  path '/api/v1/users' do
    post('회원가입') do
      tags 'Users'
      description '새 사용자 회원가입'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :user, in: :body, schema: {
        '$ref' => '#/components/schemas/UserCreateRequest'
      }

      response(201, '회원가입 성공') do
        let(:user) do
          {
            user: {
              email: 'test@example.com',
              password: 'password123'
            }
          }
        end

        schema '$ref' => '#/components/schemas/SuccessResponse'

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq('success')
          expect(data['message']).to eq('회원가입이 완료되었습니다.')
          expect(data['data']['email']).to eq('test@example.com')
        end
      end

      response(422, '회원가입 실패 - 유효성 검증 오류') do
        let(:user) do
          {
            user: {
              email: '',
              password: ''
            }
          }
        end

        schema '$ref' => '#/components/schemas/ErrorResponse'

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq('error')
          expect(data['message']).to eq('회원가입에 실패했습니다.')
          expect(data['errors']).to be_an(Array)
        end
      end

      response(422, '회원가입 실패 - 이메일 중복') do
        let(:user) do
          {
            user: {
              email: 'duplicate@example.com',
              password: 'password123'
            }
          }
        end

        before do
          User.create!(email: 'duplicate@example.com', password: 'password123')
        end

        schema '$ref' => '#/components/schemas/ErrorResponse'

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq('error')
          expect(data['message']).to eq('회원가입에 실패했습니다.')
          expect(data['errors']).to include('Email has already been taken')
        end
      end
    end
  end
end
