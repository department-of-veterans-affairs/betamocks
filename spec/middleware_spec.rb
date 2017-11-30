# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Betamocks::Middleware do
  context 'with a valid config' do
    before(:each) do
      Betamocks.configure do |config|
        config.enabled = true
        config.recording = true
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
            'spec', 'support', 'cache', 'bnb', 'book.yml'
          )
        end

        context 'in recording mode' do
          before { Betamocks.configure { |config| config.recording = true } }
          it 'creates a cache file' do
            VCR.use_cassette('infinite_jest') do
              conn.get '/doc/resource/009407494.json'
              expect(File).to exist(File.join(Dir.pwd, cache_path))
            end
          end
        end

        context 'not in recording mode' do
          before do
            Betamocks.configure { |config| config.recording = false }
          end

          it 'raises an exception when no default exists' do
            VCR.use_cassette('infinite_jest') do
              expect{conn.get '/doc/resource/111111111.json'}.to raise_error(IOError)
            end
          end
        end
      end

      context 'with a cached request' do
        before do
          cache_dir = File.join(Dir.pwd, 'spec', 'support', 'cache', 'bnb')
          cached = File.join(Dir.pwd, 'spec', 'support', 'responses', 'book.yml')
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
            File.join('spec', 'support', 'cache', 'multi', 'body', '111223333.yml')
          end

          it 'has the expected file name' do
            VCR.use_cassette('request_bin_post') do
              conn.post '/tithviti', xml
              expect(File).to exist(File.join(Dir.pwd, cache_path))
            end
          end
        end

        context 'with a request that includes multiple identifiers in the request body' do
          let(:xml) do
            '<soap:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:v1="http://viers.va.gov/cdi/CDI/commonService/v1" xmlns:v12="http://viers.va.gov/cdi/eMIS/RequestResponse/v1" xmlns:v13="http://viers.va.gov/cdi/eMIS/commonService/v1" xmlns:v11="http://viers.va.gov/cdi/eMIS/RequestResponse/MilitaryInfo/v1">
          <soap:Header>
            <v1:inputHeaderInfo>
              <v1:userId>vets.gov</v1:userId>
              <v1:sourceSystemName>vets.gov</v1:sourceSystemName>
              <v1:transactionId>245e2072-c7a6-48f0-a429-549355af5cf9</v1:transactionId>
            </v1:inputHeaderInfo>
          </soap:Header>
          <soap:Body>
            <v11:eMISserviceEpisodeRequest>
              <v12:edipiORicn>
                <v13:edipiORicnValue>1607472595</v13:edipiORicnValue>
                <v13:inputType>EDIPI</v13:inputType>
              </v12:edipiORicn>
            </v11:eMISserviceEpisodeRequest>
          </soap:Body>
        </soap:Envelope>'
          end
          let(:cache_path) do
            File.join('spec', 'support', 'cache', 'multi', 'body', 'captures', 'EpisodeRequest_1607472595.yml')
          end

          it 'has the expected file name' do
            VCR.use_cassette('request_bin_post_multiple') do
              conn.post '/tithvitj', xml
              expect(File).to exist(File.join(Dir.pwd, cache_path))
            end
          end
        end

        context 'with a request that includes the identifier in the request headers' do
          let(:cache_path) do
            File.join('spec', 'support', 'cache', 'multi', 'header', '1607472595.yml')
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
            File.join('spec', 'support', 'cache', 'multi', 'query', '2776f8b0-93eb-11e7-abc4-cec278b6b50a.yml')
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

          let(:cache_dir) do
            File.join(Dir.pwd, 'spec', 'support', 'cache', 'multi', 'url')
          end
          let(:cache_path) { File.join(cache_dir, 'W1AW.yml') }
          let(:default_file) { File.join(Dir.pwd, 'spec', 'support', 'responses', 'default.yml') }

          context 'in recording mode' do
            before { Betamocks.configure { |config| config.recording = true } }

            it 'saves the expected file name' do
              VCR.use_cassette('callook_url') do
                conn.get '/W1AW/json'
                expect(File).to exist(File.join(cache_path))
              end
            end
          end

          context 'not in recording mode with a default defined' do
            before do
              Betamocks.configure { |config| config.recording = false }
              FileUtils.mkdir_p(cache_dir)
              FileUtils.cp(default_file, cache_dir)
            end

            it 'logs a warning' do
              expect(Betamocks.logger).to receive(:warn).with(/Mock response not found/)
              VCR.use_cassette('callook_url') do
                conn.get '/W1AW/json'
              end
            end

            it 'responds with default' do
              VCR.use_cassette('callook_url') do
                response = conn.get '/W1AW/json'
                expect(File).to_not exist(cache_path)
                expect(response.status).to eq(404)
              end
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
    FileUtils.rm_rf(Dir.glob(File.join(Dir.pwd, 'spec', 'support', 'cache', '*')))
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end
end
