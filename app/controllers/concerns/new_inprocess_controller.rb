module NewInprocessController

  def index
    @order_details = new_or_in_process_orders
                     .includes(
                       { order: :user },
                       :order_status,
                       :assigned_user,
                     )
                     .order(sort_clause)
                     .paginate(page: params[:page])
  end

  private

  def new_or_in_process_orders
    raise NotImplementedError
  end

end
