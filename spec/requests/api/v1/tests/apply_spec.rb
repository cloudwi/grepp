require "rails_helper"

RSpec.describe "POST /api/v1/tests/:id/apply", type: :request do
  let(:user) { User.create!(email: "test@example.com", password: "password123") }
  let(:test) { Test.create!(title: "프로그래밍 시험", start_date: 1.day.from_now, end_date: 2.days.from_now, price: 50000) }
  let(:token) { user.generate_jwt_token }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }
  let(:valid_params) do
    {
      amount: 50000,
      payment_method: "kakaopay"
    }
  end

  describe "시험 응시 신청" do
    context "유효한 요청인 경우" do
      it "응시 신청과 결제가 성공적으로 처리됩니다" do
        post "/api/v1/tests/#{test.id}/apply", params: valid_params, headers: headers

        expect(response).to have_http_status(:created)
        json = response.parsed_body

        expect(json["status"]).to eq("success")
        expect(json["message"]).to eq("시험 응시 신청이 완료되었습니다.")
        expect(json["data"]["test_id"]).to eq(test.id)
        expect(json["data"]["test_title"]).to eq(test.title)
        expect(json["data"]["payment"]["amount"]).to eq(50000)
        expect(json["data"]["payment"]["payment_method"]).to eq("paypal")
        expect(json["data"]["payment"]["status"]).to eq("completed")

        registration = TestRegistration.find(json["data"]["registration_id"])
        expect(registration.user).to eq(user)
        expect(registration.test).to eq(test)

        payment = registration.payment
        expect(payment).to be_present
        expect(payment.amount).to eq(50000)
        expect(payment.payment_method).to eq("paypal")
        expect(payment.status).to eq("completed")
        expect(payment.user).to eq(user)
      end

      it "다양한 결제 방법을 지원합니다" do
        params = { amount: 50000, payment_method: "card" }
        post "/api/v1/tests/#{test.id}/apply", params: params, headers: headers

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json["data"]["payment"]["payment_method"]).to eq("credit_card")
      end
    end

    context "이미 신청한 시험인 경우" do
      before do
        TestRegistration.create!(user: user, test: test)
      end

      it "중복 신청 에러를 반환합니다" do
        post "/api/v1/tests/#{test.id}/apply", params: valid_params, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body

        expect(json["status"]).to eq("error")
        expect(json["message"]).to eq("이미 신청한 시험입니다.")
      end
    end

    context "존재하지 않는 시험인 경우" do
      it "404 에러를 반환합니다" do
        post "/api/v1/tests/999/apply", params: valid_params, headers: headers

        expect(response).to have_http_status(:not_found)
        json = response.parsed_body

        expect(json["status"]).to eq("error")
        expect(json["message"]).to eq("시험을(를) 찾을 수 없습니다.")
      end
    end

    context "인증되지 않은 사용자인 경우" do
      it "401 에러를 반환합니다" do
        post "/api/v1/tests/#{test.id}/apply", params: valid_params

        expect(response).to have_http_status(:unauthorized)
        json = response.parsed_body

        expect(json["status"]).to eq("error")
        expect(json["message"]).to eq("인증이 필요합니다.")
      end
    end

    context "잘못된 파라미터인 경우" do
      it "amount가 없으면 에러를 반환합니다" do
        params = { payment_method: "kakaopay" }
        post "/api/v1/tests/#{test.id}/apply", params: params, headers: headers

        expect(response).to have_http_status(:bad_request)
      end

      it "payment_method가 없으면 에러를 반환합니다" do
        params = { amount: 50000 }
        post "/api/v1/tests/#{test.id}/apply", params: params, headers: headers

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
