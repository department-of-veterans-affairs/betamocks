# frozen_string_literal: true

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
          cache_dir: 'spec/support/cache',
          services:
            [
              {
                base_urls: ['va.service.that.timesout', 'int.va.service.that.timesout'],
                endpoints: [{ method: :get, path: '/v0/users/*/forms' }]
              },
              {
                base_urls: ['bnb.data.bl.uk'],
                endpoints: [{ method: :get, path: '/doc/resource/*' }]
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
      expect(
        Betamocks.configuration.mock_endpoint?('bnb.data.bl.uk', :get, '/doc/resource/009407494.json')
      ).to be_truthy
    end

    it 'responds as false if the endpoint is not mocked' do
      expect(Betamocks.configuration.mock_endpoint?('foo.com', :get, '/v2/bar.json')).to be_falsey
    end
  end
end
