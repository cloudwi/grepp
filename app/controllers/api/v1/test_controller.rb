class Api::V1::TestController < ApplicationController
  def protected_endpoint
    render json: {
      status: 'success',
      message: '인증된 사용자만 접근 가능합니다.',
      data: {
        user: {
          id: current_user.id,
          email: current_user.email
        },
        timestamp: Time.current
      }
    }
  end
end