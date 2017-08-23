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
          'spec', 'support', 'cache', 'bnb.data.bl.uk', 'doc', 'resource', '009407494.json_09a2127d.yml'
        )
      end

      it 'creates a cache file' do
        VCR.use_cassette('infinite_jest') do
          conn.get '/doc/resource/009407494.json'
          expect(File).to exist(File.join(Dir.pwd, cache_path))
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
        File.join('spec', 'support', 'cache', 'va.service.that.timesout', 'v0', 'users', '42')
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

    context 'with a request that include a timestamp in the body' do
      let(:conn) do
        Faraday.new(url: 'https://requestb.in/tithviti') do |faraday|
          faraday.response :betamocks
          faraday.adapter Faraday.default_adapter
        end
      end
      let(:xml) do
        "<env:Envelope xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\">
           <env:Body>
             <id extension=\"WSDOC1610281012015841158653421\" root=\"2.16.840.1.113883.4.349\"/>
             <creationTime value=\"#{Time.now.utc.strftime('%Y%m%d%H%M%S')}\"/>
             <versionCode code=\"3.0\"/>
           </env:Body>
         </env:Envelope>"
      end
      let(:cache_path) do
        File.join('spec', 'support', 'cache', 'requestb.in', 'tithviti_aaeb61ac.yml')
      end

      it 'has the expected file name' do
        VCR.use_cassette('request_bin_post') do
          conn.post '/tithviti', xml
          expect(File).to exist(File.join(Dir.pwd, cache_path))
        end
      end
    end

    after(:each) do
      FileUtils.rm_rf(File.join(Dir.pwd, 'spec', 'support', 'cache'))
    end
  end
end
