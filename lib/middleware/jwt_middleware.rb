class JwtMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    # Skip JWT authentication for specific routes
    if skip_auth_route?(request.path, request.request_method)
      return @app.call(env)
    end

    # Extract JWT token from Authorization header
    token = extract_token_from_header(request)

    unless token
      return unauthorized_response("Missing authorization token")
    end

    begin
      # Decode and verify JWT token
      decoded_token = decode_jwt_token(token)
      user_id = decoded_token["user_id"]

      # Find user and set in environment
      user = User.find_by(id: user_id)
      unless user
        return unauthorized_response("Invalid token: user not found")
      end

      # Add current user to environment for controllers to access
      env["current_user"] = user
      env["current_user_id"] = user.id

    rescue JWT::DecodeError => e
      return unauthorized_response("Invalid token format")
    rescue JWT::ExpiredSignature => e
      return unauthorized_response("Token has expired")
    rescue StandardError => e
      return unauthorized_response("Token verification failed")
    end

    @app.call(env)
  end

  private

  def skip_auth_route?(path, method)
    # Routes that don't require JWT authentication
    skip_routes = [
      { path: "/api/v1/users", method: "POST" },      # 회원가입
      { path: "/api/v1/login", method: "POST" },      # 로그인
      { path: "/up", method: "GET" },                 # Health check
      { path: "/api-docs", method: "GET" }           # Swagger UI
    ]

    # Also skip if path starts with /api-docs (for swagger assets)
    return true if path.start_with?("/api-docs")

    skip_routes.any? do |route|
      path == route[:path] && method.upcase == route[:method].upcase
    end
  end

  def extract_token_from_header(request)
    auth_header = request.get_header("HTTP_AUTHORIZATION")
    return nil unless auth_header

    # Expected format: "Bearer <token>"
    if auth_header.start_with?("Bearer ")
      auth_header.split(" ").last
    else
      nil
    end
  end

  def decode_jwt_token(token)
    JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: "HS256" }).first
  end

  def unauthorized_response(message)
    [
      401,
      { "Content-Type" => "application/json" },
      [ JSON.generate({
        status: "error",
        message: "인증이 필요합니다.",
        errors: [ message ]
      }) ]
    ]
  end
end
