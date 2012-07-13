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
    @@services[k]=v.constantize

    # when we no longer have to support Ruby 1.8.7 use #define_singleton_method
    class_eval %Q[
      def self.#{k}_service
        @@services[:#{k}]
      end
    ]
  end

end