require 'spec_helper'

RSpec.describe Betamocks::Middleware do
  before do
    Betamocks.configure do |config|
      config.config_path = File.join(Dir.pwd, 'spec', 'support', 'betamocks.yml')
    end
  end

  describe 'request caching' do
    let(:conn) do
      Faraday.new(:url => 'http://bnb.data.bl.uk') do |faraday|
        puts faraday.inspect
        faraday.response :betamocks
        faraday.adapter Faraday.default_adapter
      end
    end
    let(:cache_path) do
      File.join(
        'spec',
        'support',
        'cache',
        'bnb.data.bl.uk',
        'doc',
        'resource',
        '009407494.json',
        'cad9d204e57181473ed9b1a8618e0ec6.yml'
      )
    end

    context 'with an uncached request' do
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
          expect_any_instance_of(Betamocks::Middleware).to receive(:load_env).once
          conn.get '/doc/resource/009407494.json'
          conn.get '/doc/resource/009407494.json'
        end
      end
    end

    after(:each) do
      # FileUtils.rm_rf(File.join(Dir.pwd, 'spec', 'support', 'cache'))
    end
  end

  describe 'request stubbing' do
    let(:conn) do
      Faraday.new(:url => 'http://va.service.that.timesout') do |faraday|
        faraday.response :betamocks
        faraday.adapter Faraday.default_adapter
      end
    end

    it 'loads the stub file' do
      conn.get '/v0/users/42/forms'
    end
  end
end
