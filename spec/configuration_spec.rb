require 'spec_helper'

RSpec.describe Betamox::Configuration do
  describe 'config_file_path' do
    context 'with a file that exists' do
      before do
        Betamox.configure do |config|
          config.routes_path = File.join(File.dirname(__FILE__), 'support', 'betamox_routes.yml')
        end
      end

      it 'loads the routes' do
        expect(Betamox.configuration.routes).to eq(5)
      end
    end
  end
end
