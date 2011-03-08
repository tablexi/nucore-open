module NUCore
  class PermissionDenied < SecurityError
  end
  class MixedFacilityCart < Exception
  end
  class NotPermittedWhileActingAs < Exception
  end

  def self.portal
    return 'nucore'
  end

  def self.app_name
    return 'NU Core'
  end
end
