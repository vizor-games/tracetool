require_relative '../utils/serialize'
require_relative '../utils/string'
require_relative '../utils/provider'
require_relative '../utils/trace_parser'

require_relative '../tracetool/android'
require_relative '../tracetool/ios'
require_relative '../tracetool/version'

module Tracetool
  # Trace unpacker with persistant data store and machine readable results
  class TracetoolService
    include Tracetool::Utils
    include Tracetool

    PLATFORMS = [:ios, :android].freeze

    def self.platforms
      PLATFORMS
    end

    def initialize(config)
      @providers = Hash[*config
                   .select { |k, _| PLATFORMS.include?(k) }
                   .flat_map { |k, v| [k, Provider[v]] }]
    end

    def process(platform, data)
      data = JSON.parse(data, symbolize_names: true) if data.is_a? String
      symbols = symbols_dir(platform, data)
      case platform
      when :ios
        { status: :ok, result: process_ios(symbols, data) }
      when :android
        { status: :ok, result: process_android(symbols, data) }
      end
    rescue StandardError => x
      { status: :error, reason: x.backtrace, message: x }
    end

    private

    def process_android(symbols, data)
      unpacked = Android.scan(data[:throwable], data[:cpu_abi], symbols)
      AndroidTraceParser.new(symbols).parse(unpacked)
    end

    def process_ios(symbols, data)
      dsyms = File.dirname(Dir[File.join(symbols, '**', 'dSYMs')].first)
      unpacked = IOS.scan(data[:throwable], data[:cpu_abi], dsyms, data[:module], data[:address])
      IOSTraceParser.new(symbols).parse(unpacked)
    end

    def symbols_dir(platform, data)
      @providers[platform].get(data[:build_name])
    end
  end
end
