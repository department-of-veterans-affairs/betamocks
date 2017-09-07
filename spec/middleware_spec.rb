# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Betamocks::Middleware do
  context 'with a valid config' do
    before(:each) do
      Betamocks.configure do |config|
        config.enabled = true
        config.cache_dir = File.join(Dir.pwd, 'spec', 'support', 'cache')
        config.services_config = File.join(Dir.pwd, 'spec', 'support', 'betamocks.yml')
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
            'spec', 'support', 'cache', 'doc', 'resource', '009407494.json.yml'
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
        before do
          cache_dir = File.join(Dir.pwd, 'spec', 'support', 'cache', 'doc', 'resource')
          cached = File.join(Dir.pwd, 'spec', 'support', 'responses', '009407494.json.yml')
          FileUtils.mkdir_p(cache_dir)
          FileUtils.cp(cached, cache_dir)
        end

        it 'loads the cached file' do
          VCR.use_cassette('infinite_jest') do
            expect_any_instance_of(Betamocks::ResponseCache).to_not receive(:cache_response)
            response = conn.get '/doc/resource/009407494.json'
            expect(response).to be_a(Faraday::Response)
          end
        end
      end

      context 'when multiple response caching is enabled' do
        let(:conn) do
          Faraday.new(url: 'https://requestb.in') do |faraday|
            faraday.response :betamocks
            faraday.adapter Faraday.default_adapter
          end
        end

        context 'with a request that includes the identifier in the request body' do
          let(:xml) do
            "<env:Envelope xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\">
           <env:Body>
             <livingSubjectId>
               <value root=\"2.16.840.1.113883.4.1\" extension=\"111223333\" />
             </livingSubjectId>
             <id extension=\"WSDOC1610281012015841158653421\" root=\"2.16.840.1.113883.4.349\"/>
             <versionCode code=\"3.0\"/>
           </env:Body>
         </env:Envelope>"
          end
          let(:cache_path) do
            File.join('spec', 'support', 'cache', 'requestbin', 'tithviti_111223333.yml')
          end

          it 'has the expected file name' do
            VCR.use_cassette('request_bin_post') do
              conn.post '/tithviti', xml
              expect(File).to exist(File.join(Dir.pwd, cache_path))
            end
          end
        end

        context 'with a request that includes the identifier in the request headers' do
          let(:cache_path) do
            File.join('spec', 'support', 'cache', 'requestbin', '1gv9b4e1_1607472595.yml')
          end

          it 'has the expected file name' do
            VCR.use_cassette('request_bin_headers') do
              conn.get '/1gv9b4e1' do |req|
                req.headers['va_eauth_dodedipnid'] = '1607472595'
              end
              expect(File).to exist(File.join(Dir.pwd, cache_path))
            end
          end
        end

        context 'with a request that includes the identifier in the querystring' do
          let(:cache_path) do
            File.join('spec', 'support', 'cache', 'requestbin', '1obp6rj1_2776f8b0-93eb-11e7-abc4-cec278b6b50a.yml')
          end

          it 'has the expected file name' do
            VCR.use_cassette('request_bin_querystring') do
              conn.get '/1obp6rj1?uuid=2776f8b0-93eb-11e7-abc4-cec278b6b50a'
              expect(File).to exist(File.join(Dir.pwd, cache_path))
            end
          end
        end

        context 'with a request that includes the identifier in the url' do
          let(:conn) do
            Faraday.new(url: 'https://callook.info') do |faraday|
              faraday.response :betamocks
              faraday.adapter Faraday.default_adapter
            end
          end

          let(:cache_path) do
            File.join('spec', 'support', 'cache', 'callook', 'json_W1AW.yml')
          end

          it 'has the expected file name' do
            VCR.use_cassette('callook_url') do
              conn.get '/W1AW/json'
              expect(File).to exist(File.join(Dir.pwd, cache_path))
            end
          end
        end
      end

      context 'when the endpoint is configured to return an error' do
        let(:conn) do
          Faraday.new(url: 'http://va.service.that.timesout') do |faraday|
            faraday.response :betamocks
            faraday.adapter Faraday.default_adapter
          end
        end

        it 'raises a Faraday::ClientError' do
          expect { conn.get '/v0/users/42/forms' }.to raise_error Faraday::ClientError
        end
      end

      context 'when betamocks is disabled' do
        before do
          Betamocks.configure do |config|
            config.enabled = false
            config.cache_dir = File.join(Dir.pwd, 'spec', 'support', 'cache')
            config.services_config = File.join(Dir.pwd, 'spec', 'support', 'betamocks.yml')
          end
        end
        let(:conn) do
          Faraday.new(url: 'http://bnb.data.bl.uk') do |faraday|
            faraday.response :betamocks
            faraday.adapter Faraday.default_adapter
          end
        end

        it 'does not try to cache or load a response and passes it through' do
          VCR.use_cassette('infinite_jest') do
            expect_any_instance_of(Betamocks::ResponseCache).to_not receive(:load_response)
            expect_any_instance_of(Betamocks::ResponseCache).to_not receive(:cache_response)
            response = conn.get '/doc/resource/009407494.json'
            expect(response).to be_a(Faraday::Response)
          end
        end
      end

      context 'in test environments' do
        context 'in a rails test environment' do
          it 'does not try to cache or load a response and passes it through' do
            with_modified_env RAILS_ENV: 'test' do
              VCR.use_cassette('infinite_jest') do
                expect_any_instance_of(Betamocks::ResponseCache).to_not receive(:load_response)
                expect_any_instance_of(Betamocks::ResponseCache).to_not receive(:cache_response)
                response = conn.get '/doc/resource/009407494.json'
                expect(response).to be_a(Faraday::Response)
              end
            end
          end
        end

        context 'in a rack test environment' do
          it 'does not try to cache or load a response and passes it through' do
            with_modified_env RACK_ENV: 'test' do
              VCR.use_cassette('infinite_jest') do
                expect_any_instance_of(Betamocks::ResponseCache).to_not receive(:load_response)
                expect_any_instance_of(Betamocks::ResponseCache).to_not receive(:cache_response)
                response = conn.get '/doc/resource/009407494.json'
                expect(response).to be_a(Faraday::Response)
              end
            end
          end
        end
      end
    end
  end

  after(:each) do
    FileUtils.rm_rf(File.join(Dir.pwd, 'spec', 'support', 'cache'))
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end
end
