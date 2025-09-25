require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Grepp API V1',
        version: 'v1',
        description: 'Grepp 플랫폼 API 문서'
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        }
      ],
      components: {
        schemas: {
          User: {
            type: 'object',
            properties: {
              id: { type: 'integer', example: 1 },
              email: { type: 'string', format: 'email', example: 'user@example.com' }
            },
            required: ['id', 'email']
          },
          UserCreateRequest: {
            type: 'object',
            properties: {
              user: {
                type: 'object',
                properties: {
                  email: { type: 'string', format: 'email', example: 'user@example.com' },
                  password: { type: 'string', example: 'password123' }
                },
                required: ['email', 'password']
              }
            },
            required: ['user']
          },
          SuccessResponse: {
            type: 'object',
            properties: {
              status: { type: 'string', example: 'success' },
              message: { type: 'string', example: '회원가입이 완료되었습니다.' },
              data: { '$ref' => '#/components/schemas/User' }
            },
            required: ['status', 'message', 'data']
          },
          LoginRequest: {
            type: 'object',
            properties: {
              user: {
                type: 'object',
                properties: {
                  email: { type: 'string', format: 'email', example: 'user@example.com' },
                  password: { type: 'string', example: 'password123' }
                },
                required: ['email', 'password']
              }
            },
            required: ['user']
          },
          LoginSuccessResponse: {
            type: 'object',
            properties: {
              status: { type: 'string', example: 'success' },
              message: { type: 'string', example: '로그인이 완료되었습니다.' },
              data: {
                type: 'object',
                properties: {
                  user: { '$ref' => '#/components/schemas/User' },
                  token: { type: 'string', example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' }
                },
                required: ['user', 'token']
              }
            },
            required: ['status', 'message', 'data']
          },
          ErrorResponse: {
            type: 'object',
            properties: {
              status: { type: 'string', example: 'error' },
              message: { type: 'string', example: '회원가입에 실패했습니다.' },
              errors: {
                type: 'array',
                items: { type: 'string' },
                example: ['Email can\'t be blank', 'Password can\'t be blank']
              }
            },
            required: ['status', 'message', 'errors']
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end