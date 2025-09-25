class Api::V1::TestsController < ApplicationController
  def index
    tests = Test.all.order(:start_date)

    render json: {
      status: 'success',
      message: '시험 목록 조회가 완료되었습니다.',
      data: {
        tests: tests.map do |test|
          {
            id: test.id,
            title: test.title,
            start_date: test.start_date,
            end_date: test.end_date,
            status: test_status(test)
          }
        end
      }
    }
  end

  private

  def test_status(test)
    current_time = Time.current

    if current_time < test.start_date
      'upcoming'
    elsif current_time >= test.start_date && current_time <= test.end_date
      'available'
    else
      'past'
    end
  end
end