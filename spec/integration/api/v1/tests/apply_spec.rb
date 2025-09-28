require "swagger_helper"

RSpec.describe "api/v1/tests", type: :request do
  path "/api/v1/tests/{id}/apply" do
    post("시험 응시 신청") do
      tags "Tests"
      description "시험에 응시 신청하고 결제 정보를 저장합니다."
      produces "application/json"
      consumes "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :id, in: :path, type: :integer, description: "시험 ID", required: true
      parameter name: :application_request, in: :body, schema: {
        type: :object,
        properties: {
          amount: { type: :integer, example: 45000, description: "결제 금액" },
          payment_method: { type: :string, example: "kakaopay", description: "결제 방법" }
        },
        required: [ "amount", "payment_method" ]
      }

      response(201, "응시 신청 성공") do
        before do
          @user = User.create!(email: "test@example.com", password: "password123")
          @test = Test.create!(title: "프로그래밍 시험", start_date: 1.day.from_now, end_date: 2.days.from_now)
          token = @user.generate_jwt_token
          header "Authorization", "Bearer #{token}"
        end

        let(:id) { @test.id }
        let(:application_request) { { amount: 45000, payment_method: "kakaopay" } }

        schema "$ref" => "#/components/schemas/TestApplicationResponse"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("success")
          expect(data["message"]).to eq("시험 응시 신청이 완료되었습니다.")
          expect(data["data"]["test_id"]).to eq(@test.id)
          expect(data["data"]["payment"]["status"]).to eq("completed")
        end
      end

      response(422, "중복 신청") do
        before do
          @user = User.create!(email: "test@example.com", password: "password123")
          @test = Test.create!(title: "프로그래밍 시험", start_date: 1.day.from_now, end_date: 2.days.from_now)
          TestRegistration.create!(user: @user, test: @test)
          token = @user.generate_jwt_token
          header "Authorization", "Bearer #{token}"
        end

        let(:id) { @test.id }
        let(:application_request) { { amount: 45000, payment_method: "kakaopay" } }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["message"]).to eq("이미 신청한 시험입니다.")
        end
      end

      response(404, "시험을 찾을 수 없음") do
        before do
          @user = User.create!(email: "test@example.com", password: "password123")
          token = @user.generate_jwt_token
          header "Authorization", "Bearer #{token}"
        end

        let(:id) { 999 }
        let(:application_request) { { amount: 45000, payment_method: "kakaopay" } }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["message"]).to eq("시험을 찾을 수 없습니다.")
        end
      end

      response(401, "인증 실패") do
        let(:id) { 1 }
        let(:application_request) { { amount: 45000, payment_method: "kakaopay" } }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["message"]).to eq("인증이 필요합니다.")
        end
      end
    end
  end
end
