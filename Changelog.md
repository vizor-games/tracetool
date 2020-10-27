# Version 0.5.3

* Fine grained iOS trace parsing to handle binary names with spaces correctly.

# Version 0.5.2

* Allow iOS module name to contain spaces

# Version 0.5.1

* Catch process error if atos fails to decode trace

# Version 0.5.0

* Android unpacker does not need to know about cpu abi. We use just direct path to object files

# Version 0.4.2

* CLI accepts arm64-v8a arch
* Allow negative integers in packed format
* Allow \_, ! symbols in library name

# Version 0.4.1

* Fix issue when java traces with (Unknown Source) tag were unmatched
* [#4](https://github.com/vizor-games/tracetool/pull/4) Fixed false negative match for android native stacktraces with signed addresses
* [#5](https://github.com/vizor-games/tracetool/pull/5) When parsing unpacked stack trace with multiple source files matched choose files with longest common postfix
  with original file.
* [#6](https://github.com/vizor-games/tracetool/pull/6) Fixed issue when ambiguous file names were resolved wrongly.
* Fixed issue when library path contained `=` symbol led `NativeTraceParser` to drop all lines.
* Fixed issue when java traces were not recognized
* Fixed issue when native trace could not be unpacked due missing library string

# Version 0.4.0

* [#1](https://github.com/vizor-games/tracetool/pull/1) Made stack trace parser API usable.
  * Moved CLI related logic from tracetool.rb to tracetool_cli
  * `tracetool.rb` is now for requiring stuff all together
  * `IOSTraceScanner`, `AndroidTraceScanner` are now having method `#parser` returning
    appropriate parser instance matching stack trace format
  * Test cases refactored to be less verbose.

# Version 0.3.0


## Added

* iOS crash desymbolication
* Android native crash desymbolication
* Android Native, Android Java and iOS desymbolicated crashes parsing API
