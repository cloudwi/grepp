class Api::V1::UsersController < ApplicationController
  def create
    user = User.new(user_params)

    if user.save
      render json: {
        status: 'success',
        message: '회원가입이 완료되었습니다.',
        data: {
          id: user.id,
          email: user.email
        }
      }, status: :created
    else
      render json: {
        status: 'error',
        message: '회원가입에 실패했습니다.',
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password)
  end
end