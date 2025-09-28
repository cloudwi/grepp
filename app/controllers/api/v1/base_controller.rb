class Api::V1::BaseController < ApplicationController
  include ApiErrorHandler

  DEFAULT_PAGE_SIZE = 20
  MAX_PAGE_SIZE = 100
  MIN_PAGE_NUMBER = 1

  private

  def apply_pagination(relation)
    page = [ params[:page].to_i, MIN_PAGE_NUMBER ].max
    per_page = [ (params[:per_page] || DEFAULT_PAGE_SIZE).to_i, MAX_PAGE_SIZE ].min

    relation.page(page).per(per_page)
  end

  def build_pagination_meta(paginated_relation)
    {
      current_page: paginated_relation.current_page,
      total_pages: paginated_relation.total_pages,
      total_count: paginated_relation.total_count,
      per_page: paginated_relation.limit_value,
      has_next_page: !paginated_relation.last_page?,
      has_prev_page: !paginated_relation.first_page?
    }
  end

  def success_response(message, data = {})
    {
      status: "success",
      message: message,
      data: data
    }
  end

  def error_response(message, errors = [])
    {
      status: "error",
      message: message,
      errors: Array(errors)
    }
  end
end
