module TabCountHelper
  def tab_counts
    @counts = {}
    [:problem_orders, :disputed_orders, :new_or_in_process_orders].each do |count|
      if params[:tabs].include? count.to_s
        @counts[count] = self.send(count).count
      end
    end
    render :json => @counts
  end
end