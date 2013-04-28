<p align="center" >
  <img src="http://jzzocc.com/images/mirb-iOS-icon-transparent.png" alt="mirb iOS icon" />
</p>

# mirb-iOS

An muby read-eval-print loop for iOS.

## Installation

[Download mirb-iOS](https://github.com/jzzocc/mirb-iOS/zipball/master) and then install dependencies using [CocoaPods](http://cocoapods.org/).

If you do not already have CocoaPods installed, do the following in Terminal:

``` bash
$ [sudo] gem install cocoapods
$ pod setup
```

Once CocoaPods is installed, do the following to install mirb-iOS' dependencies:

``` bash
$ cd /path/to/mirb-iOS
$ pod install
```

Open mirb-iOS from the .xcworkspace file (not the .xcodeproj file) and run!

## Usage

Use mirb-iOS just like irb or any other REPL:

<p align="center" >
  <img src="http://jzzocc.com/images/mirb-iOS-screenshot.png" alt="mirb iOS screenshot" />
</p>

## Credits

mirb-iOS is powered by [mruby](https://github.com/mruby/mruby) and borrows heavily from [the original mirb](https://github.com/mruby/mruby/blob/master/mrbgems/mruby-bin-mirb/tools/mirb/mirb.c). [ios-ruby-embedded](https://github.com/carsonmcdonald/ios-ruby-embedded), [DAKeyboardControl](https://github.com/danielamitay/DAKeyboardControl), [HPGrowingTextView](https://github.com/HansPinckaers/GrowingTextView) and [UIBubbleTableView](http://github.com/AlexBarinov/UIBubbleTableView) were all invaluable in the construction of mirb-iOS.

## Licence

mirb-iOS is available under the MIT license. See the LICENSE file for more info.
