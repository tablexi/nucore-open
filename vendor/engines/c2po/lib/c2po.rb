module C2po
  class Engine < Rails::Engine
    config.autoload_paths << File.join(File.dirname(__FILE__), "../lib")

    config.to_prepare do
      Facility.send :include, C2po::FacilityExtension
      FacilityAccountsController.send :include, C2po::FacilityAccountsControllerExtension
      AccountManager.send :include, C2po::AccountTypesExtension

      # make this engine's views override the main app's views
      paths=ActionController::Base.view_paths.dup
      index=paths.index{|p| p.to_s.include? 'c2po'}
      paths.unshift paths.delete_at(index)
      ActionController::Base.view_paths=paths
    end

    # make this engine's routes override the main app's routes
    # courtesy of http://stackoverflow.com/a/7040520/162876
    initializer :supersede_routing_paths, :after => :add_routing_paths do |app|
      app_paths=app.routes_reloader.paths
      index=app_paths.index{|path| path.include? 'c2po'}
      app_paths.unshift app_paths.delete_at(index)
    end
  end
end