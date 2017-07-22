require 'yaml'

module Betamox
  class Configuration
    attr_accessor :routes_path

    def routes
      raise ArgumentError, 'config.routes_path not set' unless routes_path
      raise IOError, 'config.routes_path not found' unless File.exist? routes_path
      YAML.load_file(@routes_path)
    end
  end
end
