module LdapAuthentication

  # Used in test mode to simulate requests that return nothing.
  class NullConnection

    def search(*_args)
      []
    end

  end

end
