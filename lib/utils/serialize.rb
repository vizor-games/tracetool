require 'json'
require 'yaml'

# Base tracetool module
module Tracetool
  # Default way we read json files
  def read_json(file)
    JSON.parse(IO.read(file), symbolize_names: true)
  end

  # Default way we read yaml files (symbolized)
  def read_yaml(file)
    JSON.parse(YAML.load(IO.read(file)).to_json, symbolize_names: true)
  end
end
