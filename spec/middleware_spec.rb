# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Betamocks::Middleware do
  before do
    Betamocks.configure do |config|
      config.config_path = File.join(Dir.pwd, 'spec', 'support', 'betamocks.yml')
    end
  end

  describe 'request caching' do
    let(:conn) do
      Faraday.new(url: 'http://bnb.data.bl.uk') do |faraday|
        faraday.response :betamocks
        faraday.adapter Faraday.default_adapter
      end
    end
    context 'with an uncached request' do
      let(:cache_path) do
        File.join(
          'spec', 'support', 'cache', 'bnb.data.bl.uk', 'doc', 'resource', '009407494.json_125a77e9.yml'
        )
      end

      it 'creates a cache file' do
        VCR.use_cassette('infinite_jest') do
          conn.get '/doc/resource/009407494.json'
          expect(File).to exist(
            File.join(
              Dir.pwd,
              cache_path
            )
          )
        end
      end
    end

    context 'with a cached request' do
      it 'loads the cached file' do
        VCR.use_cassette('infinite_jest') do
          expect_any_instance_of(Betamocks::Middleware).to_not receive(:cached_response)
          response = conn.get '/doc/resource/009407494.json'
          expect(response).to be_a(Faraday::Response)
        end
      end
    end

    context 'with a service that does not exist' do
      let(:conn) do
        Faraday.new(url: 'http://va.service.that.timesout') do |faraday|
          faraday.response :betamocks
          faraday.adapter Faraday.default_adapter
        end
      end
      let(:cache_path) do
        File.join(
          'spec', 'support', 'cache', 'va.service.that.timesout', 'v0', 'users', '42'
        )
      end

      it 'records a blank response' do
        response = conn.get '/v0/users/42/forms'
        expect(File).to exist(
          File.join(
            Dir.pwd,
            cache_path
          )
        )
        expect(response).to be_a(Faraday::Response)
      end
    end

    after(:each) do
      FileUtils.rm_rf(File.join(Dir.pwd, 'spec', 'support', 'cache'))
    end
  end
end
