# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Betamocks::OptionalLocator do
  let(:env) { double('Faraday::Env') }
  let(:method) { :post }
  let(:url) { URI('http://animal.pics/get_animals') }
  let(:optional_code_locator_value) { '<Quality>"HI-DEF"</Quality>' }
  let(:expected_optional_code_locator) { 'HIDEF' }

  before(:each) do
    Betamocks.configure do |config|
      config.enabled = true
      config.cache_dir = File.join(Dir.pwd, 'spec', 'support', 'cache')
      config.services_config = File.join(Dir.pwd, 'spec', 'support', 'betamocks.yml')
    end
    allow(env).to receive(:url).and_return(url)
    allow(env).to receive(:method).and_return(method)
    allow(env).to receive(:body)
    .and_return("<Animal>#{optional_code_locator_value}<AnimalType>Gorilla</AnimalType><Id>12345678</Id></Animal>")
  end

  describe '#generate' do
    subject { described_class.new(env).generate }

    context 'when cache_multiple_responses is defined in the endpoint configuration' do
      context 'when optional_code_locator is not defined in the end point configuration' do
        let(:url) { URI('http://requestb.in:443/tithviti') }

        it 'returns an empty string' do
          expect(subject).to eq('')
        end
      end

      context 'when optional_code_locator is defined in the end point configuration' do
        context 'when uid_location is set to an arbitrary value' do
          let(:url) { URI('http://garbage.day/get_garbage') }
          let(:method) { :get }

          it 'returns an empty string' do
            expect(subject).to eq('')
          end
        end

        context 'when uid_location is set to :body' do
          let(:url) { URI('http://animal.pics/get_animals') }

          it 'returns the expected optional code locator' do
            expect(subject).to eq(expected_optional_code_locator)
          end
        end
      end
    end

    context 'when cache_multiple_responses is not defined in the endpoint configuration' do
      let(:url) { URI('http://petpics.com/a/cat') }
      let(:method) { :get }

      it 'returns an empty string' do
        expect(subject).to eq('')
      end
    end
  end
end