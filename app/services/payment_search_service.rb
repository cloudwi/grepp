class PaymentSearchService
  def initialize(params, current_user)
    @params = params
    @current_user = current_user
  end

  def call
    payments_relation = build_payments_relation
    paginated_payments = apply_pagination(payments_relation)
    serialize_with_pagination(paginated_payments)
  end

  private

  attr_reader :params, :current_user

  def build_payments_relation
    current_user.payments
                .includes(:payable)
                .then { |relation| apply_status_filter(relation) }
                .then { |relation| apply_date_filter(relation) }
                .order(payment_time: :desc)
  end

  def apply_pagination(relation)
    page = [params[:page].to_i, 1].max
    per_page = [(params[:per_page] || 20).to_i, 100].min
    relation.page(page).per(per_page)
  end

  def serialize_with_pagination(paginated_payments)
    {
      payments: serialize_payments(paginated_payments),
      pagination: build_pagination_meta(paginated_payments)
    }
  end

  def serialize_payments(payments_relation)
    payments_relation.map do |payment|
      {
        id: payment.id,
        amount: payment.amount,
        payment_method: payment.payment_method,
        status: payment.status,
        payment_time: payment.payment_time,
        cancelled_at: payment.cancelled_at,
        payable_type: payment.payable_type,
        payable_id: payment.payable_id,
        item_title: get_item_title(payment.payable),
        created_at: payment.created_at
      }
    end
  end

  def apply_status_filter(relation)
    return relation if params[:status].blank?

    case params[:status]
    when "paid"
      relation.completed
    when "cancelled"
      relation.where(status: [ "cancelled", "refunded" ])
    else
      relation
    end
  end

  def apply_date_filter(relation)
    relation = relation.where(payment_time: Date.parse(params[:from])..) if params[:from].present?
    relation = relation.where(payment_time: ..Date.parse(params[:to]).end_of_day) if params[:to].present?
    relation
  end

  def get_item_title(payable)
    case payable
    when TestRegistration
      payable.test.title
    when CourseRegistration
      payable.course.title
    else
      "Unknown"
    end
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
end
