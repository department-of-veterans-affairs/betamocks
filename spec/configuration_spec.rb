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
              },
              {
                base_urls: ['requestb.in'],
                endpoints: [{ method: :post, path: '/tithviti', timestamp_regex: ['creationTime value="(\d{14})"'] }]
              }
            ]
        }
      end

      it 'loads the config' do
        expect(Betamocks.configuration.config).to eq(expected_config)
      end
    end
  end

  describe '#find_endpoint?' do
    before(:each) do
      allow(env).to receive(:url).and_return(url)
      allow(env).to receive(:method).and_return(:get)
    end

    context 'with a mocked endpoint' do
      let(:env) { double('Faraday::Env') }
      let(:url) { URI('http://bnb.data.bl.uk/doc/resource/009407494.json') }

      it 'responds as true if the endpoint is mocked' do
        expect(
          Betamocks.configuration.find_endpoint(env)
        ).to_not be_nil
      end
    end

    context 'with an unmocked endpoint' do
      let(:env) { double('Faraday::Env') }
      let(:url) { URI('http://foo.com/bar.json') }

      it 'responds as false if the endpoint is not mocked' do
        expect(Betamocks.configuration.find_endpoint(env)).to be_nil
      end
    end
  end
end
