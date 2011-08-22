class GlobalSettingsController < ApplicationController
  before_filter :authenticate_user!

  authorize_resource :class => NUCore

  layout 'two_column'


  def initialize
    @active_tab = 'global_settings'
    super
  end

end
