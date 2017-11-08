require 'ostruct'
require 'fileutils'
require_relative 'string'

module Tracetool
  module Utils
    # Base caching logic
    module CachedProvider
      def cache
        @cache = read_cache unless @cache
        @cache
      end

      def read_cache
        return JSON.parse(IO.read(cache_file)) if File.exist?(cache_file)
        {}
      end

      def cached?(build_name)
        cache.include?(build_name) && File.exist?(cache[build_name])
      end

      def put_cache(build_name, path)
        cache[build_name] = path
        STDERR.puts "Write to #{cache_file}. Mapping #{build_name} => #{path}"
        IO.write(cache_file, cache.to_json)
        path
      end

      def get_cached(build_name)
        cache[build_name]
      end

      def cache_file
        klass = self.class.name.downcase.gsub(/[:]/, '_')
        File.join(working_dir, '%s-%s.json'.format(klass, 'cache'))
      end
    end

    # Root class for all Providers
    class BaseProvider
      attr_reader :working_dir

      def set_working_dir(dir, mkdir = true)
        unless File.exist?(dir)
          FileUtils.mkdir_p(dir) if mkdir
          raise("Dir does not exist #{dir}") unless mkdir
        end
        @working_dir = dir
      end

      def simple_name
        self.class.name.split(/[:]+/).last.scan(/[A-Z][^A-Z]+/).join('_').downcase
      end
    end

    # Logic for nesting providers
    class NestedProvider < BaseProvider
      attr_reader :provider

      def initialize(provider)
        @provider = provider
      end

      def set_working_dir(dir, mkdir = true)
        super(dir, mkdir)
        @provider.set_working_dir(File.join(@working_dir, @provider.simple_name), mkdir)
      end

      def get(build_name)
        @provider.get(build_name)
      end
    end

    # Unzip inner provider result
    class ZipProvider < NestedProvider
      include Tracetool::Utils::CachedProvider

      def initialize(provider: nil)
        super(provider)
      end

      def get(build_name)
        return get_cached(build_name) if cached?(build_name)
        put_cache(build_name, unzip(provider.get(build_name), build_name))
      end

      def unzip(src, dst)
        dst = File.join(@working_dir, dst)
        `unzip #{src} -d #{dst}`
        File.absolute_path(dst)
      end
    end

    # Download file over http
    class HttpProvider < BaseProvider
      # Url pattern to extract auth and path to server
      URL_PATTERN = %r{^(?<proto>http[s]?:\/\/)(?<user>.+):(?<password>.+)@(?<path>.+)$}

      # Special aliases wich will be replaced with known values
      URL_PARAMS = {
        build_name: ':buildname:'
      }.freeze

      include Tracetool::Utils::CachedProvider
      attr_reader :auth, :url

      def initialize(url: nil)
        @auth, @url = parse_url(url)
      end

      def get(build_name)
        get_cached(build_name) if cached?(build_name)
        put_cache(build_name, download(build_name))
      end

      private

      def parse_url(url)
        auth, download_url = []
        url.match(URL_PATTERN) do |m|
          auth = OpenStruct.new(user: m[:user], password: m[:password])
          download_url = [m[:proto], m[:path]].join
        end

        raise 'URL doesn\'t match pattern %s, %s'.format(URL_PATTERN, url) unless auth && download_url

        [auth, download_url]
      end

      def download(build_name)
        link = url.gsub(URL_PARAMS[:build_name], build_name)
        user = auth.user
        password = auth.password
        dir = File.join(@working_dir, build_name)
        FileUtils.mkdir_p(dir)
        `cd #{dir} && wget --user #{user} --password #{password} #{link}`
        result = Dir["#{dir}/*"]
        STDERR.puts "Warning: Download dir contains more than one file. Returning first [#{result}]" if result.size > 1
        result.first
      end
    end

    # Top level symbols provider
    class Provider < NestedProvider
      PROVIDERS_MAP = {
        zip: Tracetool::Utils::ZipProvider,
        http: Tracetool::Utils::HttpProvider
      }.freeze

      class << self
        def [](description)
          new(scan(description))
        end

        private

        # Recursively scan description and convert all :provider mappings into
        # described providers
        def scan(description)
          params = description.flat_map do |k, v|
            v = scan(v) if v.is_a?(Hash)
            v = create_provider(v) if k == :provider
            [k, v]
          end
          Hash[*params]
        end

        # Construct provider according with description
        def create_provider(params)
          raise "Expecting only one key-value pair got #{params.size}" unless params.size == 1
          params.map do |key, value|
            PROVIDERS_MAP[key].new(value)
          end.first
        end
      end

      def initialize(provider: nil, working_dir: nil)
        super(provider)
        set_working_dir(working_dir)
      end
    end
  end
end
