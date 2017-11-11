# Tracetool

[![Coverage Status](https://img.shields.io/codeclimate/coverage/github/vizor-games/tracetool.svg)](https://codeclimate.com/github/vizor-games/tracetool)
[![Code Climate](https://codeclimate.com/github/vizor-games/tracetool/badges/gpa.svg)](https://codeclimate.com/github/vizor-games/tracetool)
[![Build Status](https://travis-ci.org/vizor-games/tracetool.svg?branch=master)](https://travis-ci.org/vizor-games/tracetool)

## Synopsis

`tracetool` is a tiny tool that makes easier process of desymbolication Android and iOS crash reports.

## Installing

To install `tracetool`, use the following command:

```sh
$ gem install tracetool
```

Alternatively, if you've checked the source out directly, you can call 

```sh
rake gem:install
```

from the root project directory.

## Usage

### tracetool Command-line Tool

`tracetool` accepts trace content through `STDIN` or from file. Tool configuration is passed through command line 
arguments. Android and iOS modes are assuming certain symbols layout. 

#### Unpacking Android Native Traces

> You need `ndk-stack` in your PATH to use this feature. See 
> [Android NDK | ndk-stack ](https://developer.android.com/ndk/guides/ndk-stack.html)
> for more information.

To process native Android stack trace you need to pass following CLI arguments: 

* `--platform android` - switch to Android mode
* `--symbols %path%` - specify compilation symbols location. You need to specify path to `local/%abi%` directory rest
 of the path will be evaluated. If no `--symbols` argument passed current directory assumed to be compilation symbols
  location. 
* `--arch` - valid Android architecture. This value is added to path.

##### Supported formats

In Android mode `tracetool` supports several formats. Main purpose here is to asthmatically generate
well-formed stack trace and pass it to `ndk-stack`

* Plain logcat trace:

```
*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
Build fingerprint: UNKNOWN
pid: 0, tid: 0
signal 0 (UNKNOWN)
backtrace:
       #00  pc 0000841e  /data/local/ndk-tests/crasher
       #01  pc 000083fe  /data/local/ndk-tests/crasher
       #02  pc 000083f6  /data/local/ndk-tests/crasher
       #03  pc 000191ac  /system/lib/libc.so
       #04  pc 000083ea  /data/local/ndk-tests/crasher
       #05  pc 00008458  /data/local/ndk-tests/crasher
       #06  pc 0000d362  /system/lib/libc.so
``` 

* Striped trace from Google Play dashboard: 
```
backtrace:
      native: pc 00000000004321ec  libvizornative.so
      native: pc 000000000042db8d  libvizornative.so
      native: pc 0000000000c35865  base.odex
```

* Packed stack trace (this is internal feature and will be dropped in future releases):

```
<<<12345678 foo.so __bar 42;12345678 foo.so __bar 42;>>>
```

> Here addresses `.so`-names packed in `;` separated string.
 
#### Unpacking Android Java Traces

> This feature is useless at the moment  

#### Unpacking iOS traces 

> You need MacOS and `atos` (XCode Tools) to use this feature. 
> See [`man atos`](https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man1/atos.1.html)
> for more information. 

To desymbolicate iOS traces you need to pass following arguments:

* `--symbols` - directory containing `dSYMs/%AppName%.app.dSYM/Contents/Resources/DWARF/%AppName%`. If no `--symbols`
 specified `tracetool` will use current directory 
* `--arch` - valid iOS arch (`x86_64` or `arm64`)
* `--address` - application load address
* `--module` - your application name. 

> To learn more about *load address* see [Understanding and Analyzing Application Crash Reports](https://developer.apple.com/library/content/technotes/tn2151/_index.html)

#### Supported trace formats

In iOS mode `tracetool` recognizes only thread stack trace format: 

```
0  Foo                                 0x00000001029b2d48 Foo + 159048
1  Foo                                 0x00000001029b37d0 Foo + 161744
2  libsystem_platform.dylib            0x00000001857dbb44 _sigtramp + 52
3  Foo                                 0x0000000102cf6178 Foo + 3580280
4  Foo                                 0x0000000102cc36c0 Foo + 3372736
5  UIKit                               0x000000018efc4078 <redacted> + 340
```

## Changelog

See [Changelog.md](Changelog.md) for a list of changes.

## Roadmap 

See [Roadmap.md](Roadmap.md) for a list of scheduled features and changes. 

## License

tracetool is licensed under the MIT licence. Please see the [LICENCE](LICENCE) for more information.
