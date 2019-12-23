# Audiograph
Audio-Feedback on Charts for visually impaired Users

![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/Tantalum73/Audiograph)
[![License](https://img.shields.io/github/license/Tantalum73/Audiograph)](LICENSE)

<a href="Media/Screenshot.png"><img width=200 height=200 src="Media/Screenshot.png" alt="Screenshot" /></a>


**This Readme is far from being complete!** I just added the most basic information about using it with a dependency manager. Examples are working but not well documented here, yet.  
I'll work on that as soon as I got some feedback about using it :)

## Example
The example app provides many things related to presenting a cool chart. I wrote about the chart in my blog. However, this project is about accessibility.  
You can find everything related to accessibility in the file `ChartView+Accessibility`.

To run the example project, clone this repo, and open iOS Example.xcworkspace from the iOS Example directory.

## Points to improve on the next Iteration
* [ ] Computing samples on a background queue
* [ ] Removing debug print statements
* [ ] Design a cool icon (since all OS projects need a logo, obviously)

A 1.0 will not launch until those points are addressed.


## Requirements


## Installation

Add this to your project using Swift Package Manager. In Xcode that is simply: File > Swift Packages > Add Package Dependency... and you're done. Alternative installations options are shown below for legacy projects.

### CocoaPods

If you are already using [CocoaPods](http://cocoapods.org), just add 'Audiograph' to your `Podfile` then run `pod install`.

### Carthage

If you are already using [Carthage](https://github.com/Carthage/Carthage), just add to your `Cartfile`:

```ogdl
github "Tantalum73/Audiograph" ~> 0.1
```

Then run `carthage update` to build the framework and drag the built `Audiograph`.framework into your Xcode project.


## Author

Andreas Neusüß


## License

Audiograph is available under the MIT license. See [the LICENSE file](LICENSE) for more information.
