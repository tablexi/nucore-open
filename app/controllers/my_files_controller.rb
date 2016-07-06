class MyFilesController < ApplicationController

  customer_tab :all
  before_action { @active_tab = "my_files" }

  def index
    @files = current_user.stored_files
      .merge(Order.purchased)
      .order(id: :desc).paginate(page: params[:page])
  end

end
