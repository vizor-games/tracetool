module Helpers
  module NativeTraceParserHelper
    HEADER = <<-HEADER.strip_indent.freeze
    ********** Crash dump: **********
    Build fingerprint: 'generic/google_sdk/generic/:2.2/FRF91/43546:eng/test-keys'
    pid: 351, tid: 351  >>> /data/local/ndk-tests/crasher <<<
    signal 11 (SIGSEGV), fault addr 0d9f00d8
    HEADER
    def with_header(lines)
      HEADER + lines
    end
  end
end
