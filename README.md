# fetchbuild
This simple library and tool allows fetching the build fingerprint and other properties of standard Android OTA files hosted on the web, without downloading the entire files.

## Setup
Before first usage fetch dart deps: `dart pub get`

## Usage
### Option 1: Compile and run
`dart compile exe bin/fetchbuild.dart && ./bin/fetchbuild <url> [extra]`

### Option 2: Run with Dart
`dart run bin/fetchbuild.dart <url> [extra keys]`

### Option 3: Use as a dart library
See `bin/fetchbuild.dart` for example usage.

### Arguments
`<url>`: The URL of the OTA file to fetch build properties from.  
`[extra keys]`: Extra keys to fetch from the OTA file (names are the same as in `META-INF/com/android/metadata`, without the `=`)