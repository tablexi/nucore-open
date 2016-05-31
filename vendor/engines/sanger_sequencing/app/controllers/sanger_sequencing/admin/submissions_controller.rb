module SangerSequencing

  module Admin

    class SubmissionsController < ApplicationController

      admin_tab :all
      before_filter { @active_tab = "admin_sanger_sequencing" }

      def index
      end

    end

  end

end
