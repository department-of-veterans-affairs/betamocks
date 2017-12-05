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
          expect(endpoint).to eq(method: :get, path: '/doc/resource/*', file_path: 'bnb/book')
        end
      end

      context 'with overlapping hosts' do
        let(:env) { double('Faraday::Env') }
        let(:url) { URI('http://bnb.data.bl.uk:8080/doc/resource/009407494.json') }

        it 'returns the correct endpoint based on port' do
          endpoint = Betamocks.configuration.find_endpoint(env)
          expect(endpoint).to eq(method: :get, path: '/doc/resource/*', file_path: 'bnb/book8080')
        end
      end

      context 'with overlapping endpoints that contain *' do
        let(:env) { double('Faraday::Env') }
        let(:url) { URI('http://bnb.data.bl.uk/doc/resource/blah/009407494.json') }

        it 'returns the correct endpoint' do
          endpoint = Betamocks.configuration.find_endpoint(env)
          expect(endpoint).to eq(method: :get, path: '/doc/resource/blah/*', file_path: 'bnb/blah_books')
        end
      end

      context 'with overlapping endpoints' do
        let(:env) { double('Faraday::Env') }
        let(:url) { URI('http://petpics.com/a/cat') }
        let(:extended_url) { URI(url.to_s + '/and/dog') }

        it 'returns the non-extended url' do
          endpoint = Betamocks.configuration.find_endpoint(env)
          expect(endpoint).to eq(method: :get, path: '/a/cat', file_path: 'cats')
        end

        it 'returns the non-extended url' do
          allow(env).to receive(:url).and_return(extended_url)
          endpoint = Betamocks.configuration.find_endpoint(env)
          expect(endpoint).to eq(method: :get, path: '/a/cat/and/dog', file_path: 'cats/with/dogs')
        end
      end

      context 'with an unmocked endpoint' do
        let(:env) { double('Faraday::Env') }
        let(:url) { URI('http://foo.com/bar.json') }

        it 'responds as false if the endpoint is not mocked' do
          expect(Betamocks.configuration.find_endpoint(env)).to be_falsey
        end
      end

      context 'with one uri that serves multiple resources' do
        let(:env) { double('Faraday::Env') }
        let(:url) { URI('http://animal.pics/get_animals') }

        it 'returns the proper endpoint for request body' do
          allow(env).to receive(:method).and_return(:post)
          allow(env).to receive(:body)
            .and_return('<AnimalType>Lion</AnimalType><Id>12345678</Id>')
          endpoint = Betamocks.configuration.find_endpoint(env)
          expect(endpoint).to include(method: :post, path: '/get_animals', file_path: '/pics/lions')
        end
      end
    end
  end


  describe '#recording' do
    before do
      Betamocks.configure do |config|
        config.enabled = true
        config.cache_dir = File.join(Dir.pwd, 'spec', 'support', 'cache')
        config.services_config = File.join(Dir.pwd, 'spec', 'support', 'betamocks.yml')
      end
    end
    context 'when the setting is true' do
      before { Betamocks.configure { |config| config.recording = true } }
      it 'recording? should be true' do
        expect(Betamocks.configuration.recording?).to be(true)
      end
    end
    context 'when the setting is "true"' do
      before { Betamocks.configure { |config| config.recording = 'true' } }
      it 'recording? should be true' do
        expect(Betamocks.configuration.recording?).to be(true)
      end
    end
    context 'when the setting is false' do
      before { Betamocks.configure { |config| config.recording = false } }
      it 'recording? should be false' do
        expect(Betamocks.configuration.recording?).to be(false)
      end
    end
    context 'when the setting is "false"' do
      before { Betamocks.configure { |config| config.recording = 'false' } }
      it 'recording? should be false' do
        expect(Betamocks.configuration.recording?).to be(false)
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

      it 'enabled? should be true' do
        expect(Betamocks.configuration.enabled?).to be true
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

      it 'enabled? should be true' do
        expect(Betamocks.configuration.enabled?).to be true
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

      it 'enabled? should be false' do
        expect(Betamocks.configuration.enabled?).to be false
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

      it 'enabled? should be false' do
        expect(Betamocks.configuration.enabled?).to be false
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

      it 'enabled? should be false' do
        expect(Betamocks.configuration.enabled?).to be false
      end
    end

    context 'when the setting is missing' do
      before do
        Betamocks.configure do |config|
          config.cache_dir = File.join(Dir.pwd, 'spec', 'support', 'cache')
          config.services_config = File.join(Dir.pwd, 'spec', 'support', 'betamocks.yml')
        end
      end

      it 'enabled? should be false' do
        expect(Betamocks.configuration.enabled?).to be false
      end
    end
  end
end
