require 'spec_helper'

RSpec.describe Betamocks::Configuration do
  before(:each) do
    Betamocks.configure do |config|
      config.config_path = File.join(File.dirname(__FILE__), 'support', 'betamocks.yml')
    end
  end

  describe '#config' do
    context 'with a file that exists' do
      let(:expected_config) do
        {
          cache_dir: 'config/betamocks',
          services:
            [
              {
                id: :pet_store,
                base_urls: %w(petstore.swagger.io dev.petstore.swagger.io),
                endpoints: %w(/v2/swagger.json)
              },
              {
                id: :vets_gov,
                base_urls: %w(dev.vets.gov staging.vets.gov),
                endpoints: %w(/v0/user)
              }
            ]
        }
      end

      it 'loads the config' do
        expect(Betamocks.configuration.config).to eq(expected_config)
      end
    end
  end

  describe '#mock_endpoint?' do
    it 'responds as true if the endpoint is mocked' do
      expect(Betamocks.configuration.mock_endpoint?('petstore.swagger.io', '/v2/swagger.json')).to be_truthy
    end

    it 'responds as false if the endpoint is not mocked' do
      expect(Betamocks.configuration.mock_endpoint?('funk.com', '/v2/lala.json')).to be_falsey
    end
  end
end
