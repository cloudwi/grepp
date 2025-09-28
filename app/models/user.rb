class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  has_many :test_registrations, dependent: :destroy
  has_many :course_registrations, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :tests, through: :test_registrations
  has_many :courses, through: :course_registrations

  def self.authenticate(email, password)
    user = find_by(email: email)
    user&.authenticate(password)
  end

  def generate_jwt_token
    payload = {
      user_id: id,
      email: email,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, Rails.application.secret_key_base)
  end
end
