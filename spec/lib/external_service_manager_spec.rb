require 'spec_helper'

describe ExternalServiceManager do

  Settings.external_services.to_hash.each do |service, klass_name|
    it 'has an accessor specific to this service' do
      expect(described_class).to respond_to "#{service}_service"
    end

    it 'returns the class set on the service' do
      expect(described_class.send("#{service}_service")).to eq klass_name.constantize
    end
  end

end
