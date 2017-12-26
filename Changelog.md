# Added 

* Fixed false negative match for android native stacktraces with signed addresses
* When parsing unpacked stack trace with multiple source files matched choose files with longest common postfix
  with original file. 
 
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
