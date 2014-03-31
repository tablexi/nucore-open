#
# This class manages all of the +ExternalService+s used by
# the system. It should be the only code aware of the actual
# external services in use by the system. Any other code should
# call the methods of this class to deal with external services.
class ExternalServiceManager

  @@services={}

  #
  # Defines class method #<service type>_service for every
  # configured service. Each method returns the class responsible
  # for handling that service type. Services are defined under
  # external_services: of settings.yml.
  Settings.external_services.to_hash.each do |k, v|
    @@services[k] = v.constantize
    define_singleton_method("#{k}_service".to_sym) { @@services[k.to_sym] }
  end

end
