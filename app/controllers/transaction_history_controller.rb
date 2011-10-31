class TransactionHistoryController < ApplicationController
  before_filter :load_filter_options
  def index
    
  end
  
  def load_filter_options
    @accounts = Account.active
    @facilities = Facility.active
  end
end
