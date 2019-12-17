# frozen_string_literal: true

class ResearchSafetyCertificationLookup

  cattr_accessor(:adapter_class) { UmassCorum::OwlApiAdapter }

  # This is a class method for easier stubbing in specs
  def self.adapter(user)
    adapter_class.new(user)
  end

  # Allows either a single certificate or an array of certificates
  def self.certified?(user, certificates)
    new(user).certified?(certificates)
  end

  def self.certificates_with_status_for(user)
    new(user).certificates_with_status
  end

  def initialize(user)
    @user = user
  end

  def certified?(certificates)
    Array(certificates).all? { |certificate| adapter.certified?(certificate) }
  end

  def missing_from(certificates)
    certificates.reject { |certificate| adapter.certified?(certificate) }
  end

  def certificates_with_status
    ResearchSafetyCertificate.ordered.each_with_object({}) do |certificate, hash|
      hash[certificate] = adapter.certified?(certificate)
    end
  end

  private

  def adapter
    self.class.adapter(@user)
  end

end
