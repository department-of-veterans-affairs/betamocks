# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Betamocks::Configuration do
  context 'with a basic setting' do
    before(:each) do
      Betamocks.configure do |config|
        config.enabled = true
        config.cache_dir = File.join(Dir.pwd, 'spec', 'support', 'cache')
        config.services_config = File.join(Dir.pwd, 'spec', 'support', 'betamocks.yml')
      end
    end

    describe '#config' do
      context 'with a file that exists' do
        it 'loads the config' do
          expect(Betamocks.configuration.config).to_not be_nil
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

        it 'returns the endpoint' do
          endpoint = Betamocks.configuration.find_endpoint(env)
          expect(endpoint).to eq(method: :get, path: '/doc/resource/*', file_path: 'doc/resource')
        end
      end

      context 'with an unmocked endpoint' do
        let(:env) { double('Faraday::Env') }
        let(:url) { URI('http://foo.com/bar.json') }

        it 'responds as false if the endpoint is not mocked' do
          expect(Betamocks.configuration.find_endpoint(env)).to be_falsey
        end
      end
    end
  end


  describe '#enabled' do
    context 'when the setting is true' do
      before do
        Betamocks.configure do |config|
          config.enabled = true
          config.cache_dir = File.join(Dir.pwd, 'spec', 'support', 'cache')
          config.services_config = File.join(Dir.pwd, 'spec', 'support', 'betamocks.yml')
        end
      end

      it 'enabled should be true' do
        expect(Betamocks.configuration.enabled).to be true
      end
    end

    context 'when the setting is "true"' do
      before do
        Betamocks.configure do |config|
          config.enabled = 'true'
          config.cache_dir = File.join(Dir.pwd, 'spec', 'support', 'cache')
          config.services_config = File.join(Dir.pwd, 'spec', 'support', 'betamocks.yml')
        end
      end

      it 'enabled should be true' do
        expect(Betamocks.configuration.enabled).to be true
      end
    end

    context 'when the setting is false' do
      before do
        Betamocks.configure do |config|
          config.enabled = false
          config.cache_dir = File.join(Dir.pwd, 'spec', 'support', 'cache')
          config.services_config = File.join(Dir.pwd, 'spec', 'support', 'betamocks.yml')
        end
      end

      it 'enabled should be false' do
        expect(Betamocks.configuration.enabled).to be false
      end
    end

    context 'when the setting is "false"' do
      before do
        Betamocks.configure do |config|
          config.enabled = 'false'
          config.cache_dir = File.join(Dir.pwd, 'spec', 'support', 'cache')
          config.services_config = File.join(Dir.pwd, 'spec', 'support', 'betamocks.yml')
        end
      end

      it 'enabled should be false' do
        expect(Betamocks.configuration.enabled).to be false
      end
    end

    context 'when the setting is nil' do
      before do
        Betamocks.configure do |config|
          config.enabled = nil
          config.cache_dir = File.join(Dir.pwd, 'spec', 'support', 'cache')
          config.services_config = File.join(Dir.pwd, 'spec', 'support', 'betamocks.yml')
        end
      end

      it 'enabled should be false' do
        expect(Betamocks.configuration.enabled).to be false
      end
    end

    context 'when the setting is missing' do
      before do
        Betamocks.configure do |config|
          config.cache_dir = File.join(Dir.pwd, 'spec', 'support', 'cache')
          config.services_config = File.join(Dir.pwd, 'spec', 'support', 'betamocks.yml')
        end
      end

      it 'enabled should be false' do
        expect(Betamocks.configuration.enabled).to be false
      end
    end
  end
end
