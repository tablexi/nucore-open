#
# This class manages all of the +ExternalService+s used by
# the system. Other than initializers, it should be the only
# code aware of the actual external services in use by the
# system. Any other code should query the generic methods of
# this class to deal with external services.
class ExternalServiceManager

  @@services={}

  #
  # Generic service types
  SERVICE_TYPES=[ :survey ]


  #
  # Defines class method #<service type>_service for every
  # +SERVICE_TYPES+. Each method returns the class responsible
  # for handling that service type.
  SERVICE_TYPES.each do |type|
    class_eval %Q[
      def self.#{type}_service
        @@services[:#{type}]
      end
    ]
  end


  #
  # Used to configure the external services that the system is using.
  # [_service_class_]
  #   Class name of an +ExternalService+ subclass
  # [_service_type_]
  #   One of the generic service types in +SERVICE_TYPES+
  def self.register_service(service_class, service_type)
    raise "Service type #{service_type} unknown!" unless SERVICE_TYPES.include?(service_type)
    @@services[service_type]=service_class
  end

end