class ResponseSet < ActiveRecord::Base
  include Surveyor::Models::ResponseSetMethods
  
  def self.find_by_access_code(access_code, options={})
    # remove lock
    options.delete(:lock)
    # add conditions
    options[:conditions] = {:access_code => access_code}
    self.find(:first, options)
  end
  
end