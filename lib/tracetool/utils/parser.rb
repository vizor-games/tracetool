require_relative 'string'

module Tracetool
  # Base trace parser logic
  class BaseTraceParser
    include StringUtils

    attr_reader :entry_pattern, :call_pattern

    def initialize(entry_pattern, call_pattern, build_files, convert_numbers = false)
      @build_files = build_files
      @entry_pattern = entry_pattern
      @call_pattern = call_pattern
      @convert_numbers = convert_numbers
    end

    # Parse crash dump
    # Each line should be parsed in Hash which SHOULD or MAY contains following
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
        .map { |line| scan_call(scan_line(line)) }
    end

    private

    # Will drop other lines from unpacked result
    def line_filter(line)
      entry_pattern.match(line)
    end

    # Find basic entry elements:
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
    # Can return multiple files if name was ambiguous
    def find_file(file)
      # Find all files with same basename
      filename = File.basename(file)
      files = @build_files.select { |f| f.end_with?(filename) }

      if files.length > 1
        # If got ambiguous files return all try to find closest match
        files = find_closest_files(file, files)
      end

      # If has only option return first
      return files.first if files.size == 1
      # Return original file if files empty
      return file if files.empty?

      files # Return all files if many matched
    end

    # Select from candidates list such files
    # that ends with maximum substring of file
    # @param [String] file file path to match
    # @param [Array<String>] candidates list of candidates path
    # @return [Array<String>] list of files with maximum length matches
    def find_closest_files(file, candidates)
      scored = candidates
               .map { |path| [file.longest_common_postfix(path).length, path] }
               .sort_by { |score, _path| -score } # from max to min
      max_score, _path = scored.first

      scored.select { |score, _path| score == max_score }.map(&:last)
    end

    def extract_groups(match)
      groups = match
               .names
               .map { |name| [name.to_sym, match[name]] }
               .flat_map { |name, value| [name, try_convert(value)] }
      Hash[*groups]
    end

    def try_convert(value)
      return value unless @convert_numbers
      return value.to_i if /^\d+$/ =~ value

      value
    end
  end
end
