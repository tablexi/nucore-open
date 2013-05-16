module Ldap
  class UserConverter
    def initialize(ldap_user)
      @ldap_user = ldap_user
    end

    def user
      User.new(:username => @ldap_user.send(Ldap.attribute_field).last,
           :first_name => @ldap_user.givenname.first,
           :last_name => @ldap_user.sn.first,
           :email => @ldap_user.mail.first)
    end
  end
end
