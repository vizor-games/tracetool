module Tracetool
  # Base trace parser logic
  class BaseTraceParser
    attr_reader :entry_pattern, :call_pattern

    def initialize(entry_pattern, call_pattern, build_dir)
      @build_dir = build_dir
      @entry_pattern = entry_pattern
      @call_pattern = call_pattern
    end

    # Parse crash dump
    # Each line should be barsed in Hash which SHOULD or MAY contains following
    # entries:
    #
    # * SHOULD contain `orig` entry -- original trace entry
    # * MAY contain following entries IF original entry matched pattern:
    # ** `frame` - stack frame index
    # ** `lib` - shared library name (android) or module name (ios)
    # ** `call_description` - original call block
    # ** MAY contain `call` entry if `call_description` was recognized:
    # *** `method` - namespaced method name (with class and its namespace)
    # *** `file` - file path relative to `symbols dir`
    # *** `line` - line number in specified file
    def parse(lines)
      lines
        .split("\n")
        .select { |line| line_filter(line) }
        .map do |line|
          scan_call(scan_line(line))
        end
    end

    private

    # Will drop other lines from unpacked result
    def line_filter(line)
      entry_pattern.match(line)
    end

    # Find basic etnry elements:
    # * frame
    # * address
    # * library
    # * call description
    def scan_line(line)
      e = { orig: line }
      entry_pattern.match(line) do |m|
        e.update(extract_groups(m))
      end
      e
    end

    # Parse call description to extract:
    # * method
    # * file
    # * line number
    def scan_call(e)
      if e[:call_description]
        call_pattern.match(e[:call_description]) do |m|
          call = extract_groups(m)
          # Update file entry with expanded path
          call[:file] = find_file(call[:file]) if call[:file]

          e[:call] = call
        end
      end

      e
    end

    # Find file with specified file name in symbols dir
    # Can return multiple files if name was ambigous
    def find_file(file)
      # Find all matching files
      # remove build_dir from path
      # remove leading '/'
      glob = File.join(@build_dir, '**', File.basename(file))
      files = Dir[glob].map { |f| f.gsub(@build_dir, '').gsub(%r{^/}, '') }

      # If has only option return first
      return files.first if files.size == 1
      # Return original file if files empty
      return file if files.empty?

      # If got ambigous files return all
      files
    end

    def extract_groups(match)
      Hash[*match.names.flat_map { |name| [name.to_sym, match[name]] }]
    end
  end

  # Android traces scanner and mapper
  class AndroidTraceParser < BaseTraceParser
    # Describes android stack entry
    STACK_ENTRY_PATTERN =
      %r{Stack frame #(?<frame>\d+)  (?<address>\w+ [a-f\d]+)  (?<lib>[/\w\d\.-]+)(: (?<call_description>.+))?$}
    # Describes android native method call (class::method and source file with line number)
    CALL_PATTERN = /(Routine )?(?<method>.+) at (?<file>.+):(?<line>\d+)/

    def initialize(build_dir)
      super(STACK_ENTRY_PATTERN, CALL_PATTERN, build_dir)
    end
  end

  # IOS traces scanner and source mapper
  class IOSTraceParser < BaseTraceParser
    # Describes IOS stack entry
    STACK_ENTRY_PATTERN = /^#(\s+)?(?<frame>\d+) (?<lib>.+) :: (?<call_description>.+)$/
    # Describes source block
    SOURCE_PATTERN = /^((?<method>.+) \(in (?<lib>.+)\) \((?<file>.+):(?<line>\d+)\))|(?<other>.+)$/

    def initialize(build_dir)
      super(STACK_ENTRY_PATTERN, SOURCE_PATTERN, build_dir)
    end
  end
end
