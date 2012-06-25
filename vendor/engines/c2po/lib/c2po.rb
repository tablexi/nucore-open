module C2po
  class Engine < Rails::Engine
    config.autoload_paths << File.join(File.dirname(__FILE__), "../lib")

    config.to_prepare do
      FacilityAccountsController.send :include, C2po::FacilityAccountsControllerExtension
    end
  end
end