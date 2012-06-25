module C2po
  class Engine < Rails::Engine
    config.autoload_paths << File.join(File.dirname(__FILE__), "../lib")

    config.to_prepare do
      Facility.send :include, C2po::FacilityExtension
      FacilityAccountsController.send :include, C2po::FacilityAccountsControllerExtension

      # make this engine's views override the main app's views
      paths=ActionController::Base.view_paths.dup
      index=paths.index{|p| p.to_s.include? 'c2po'}
      paths.unshift paths.delete_at(index)
      ActionController::Base.view_paths=paths
    end
  end
end