class Api::V1::AuthController < ApplicationController
  def login
    user = User.authenticate(login_params[:email], login_params[:password])

    if user
      token = user.generate_jwt_token
      render json: {
        status: "success",
        message: "로그인이 완료되었습니다.",
        data: {
          user: {
            id: user.id,
            email: user.email
          },
          token: token
        }
      }, status: :ok
    else
      render json: {
        status: "error",
        message: "이메일 또는 비밀번호가 올바르지 않습니다.",
        errors: [ "Invalid email or password" ]
      }, status: :unauthorized
    end
  end

  private

  def login_params
    params.expect(user: [ :email, :password ])
  end
end
