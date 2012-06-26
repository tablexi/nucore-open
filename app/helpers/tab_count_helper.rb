module TabCountHelper
  ACTIONS_TO_COUNT_TYPE = {
  	:index => :new_or_in_process_orders,
  	:show_problems => :problem_orders,
  	:disputed => :disputed_orders
  }

  def tab_counts
    @counts = {}
    ACTIONS_TO_COUNT_TYPE.values.each do |count|
      if params[:tabs].include? count.to_s
        @counts[count] = self.send(count).count
      end
    end
    render :json => @counts
  end

  def display_tab(title, link, args)
    classes = []
    if args[:action].try(:to_sym) == params[:action].try(:to_sym)
      classes << 'active'
      title << " (#{@order_details.try(:total_entries) || @order_details.count})"
    end
    link_to title, link, { :class =>  classes.join(' '), :id => ACTIONS_TO_COUNT_TYPE[args[:action]] }
  end
end