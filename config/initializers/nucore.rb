require 'nucore'

ActiveRecord::Base.class_eval do
  def self.validate_url_name(attr_name)
    validates_length_of attr_name, :in => 3..50
    validates_format_of attr_name, :with => /^[\w-]*$/, :message => "may contain letters, digits, dashes and underscores only"
    validates_uniqueness_of attr_name, :case_sensitive => false
  end
end