![](Media/Logo.jpg)
Audio-Feedback on Charts for visually impaired Users

![GitHub tag (0.1.0)](https://img.shields.io/github/v/tag/Tantalum73/Audiograph)
[![License](https://img.shields.io/github/license/Tantalum73/Audiograph)](LICENSE)

**Currently, CocoaPods is not supported, as this is a private repo.**  
**Please** provide feedback on the API, its integration, documentation and examples! :)

## Background
iOS 13 introduced an awesome way to provide stocks-charts to visually impaired users. Using a custom accessibility-rotor they are providing spoken chart analysis and an audiograph that renders the chart by using audio. That's the most accurate way of describing a chart that otherwise would only available visually.  
Take a look at the following video if you haven't tried it out yourself:

<a href="https://anerma.de/uploads/iOS_13_Audiograph.mp4"><img height=600 src="Media/iOS_13_preview.png" alt="Screenshot" /></a>

## Audiograph
Unfortunately there is no public API from Apple that enables developers to implement it in their apps (yet). I think that charts can provide a great way of presenting information, but we should not limit their use to those users without impairments.  
This is where Audiograph comes into play:

<a href="https://anerma.de/uploads/Audiograph_Demo_small.mp4"><img height=600 src="Media/Audiograph_preview.png" alt="Screenshot" /></a>

## Example
The example app provides many things related to presenting a cool chart. I wrote about the chart in my [blog](https://anerma.de/blog/tear-down-trade-republic-charts). However, this project is about accessibility.  
You can find everything related to accessibility in the file `ChartView+Accessibility`.

To run the example project, clone this repo, and open iOS Example.xcworkspace from the iOS Example directory.

## Points to improve on the next Iteration
* [x] Computing samples on a background queue
* [ ] Remove debug print statements
* [ ] Performance tests and analysis
* [ ] Design a cool icon (because all OS projects need a logo, obviously)

A version 1.0 will not launch until those points are addressed.

## Usage
After stating `import Audiograph` you keep a strong reference to it
```swift
let audiograph = Audiograph()
```
Now you are ready to play the Audiograph by calling:
```swift
audiograph.play(graphContent: points)
```
The argument is of type `[CGPoint]` and should be the same points you are using to draw your UI.

You now can trigger the Audiograph at any time you like. However, it is recommended to use it as accessibility feature.  
There are several ways to provide it to your users as such. One way is to play it as soon as the chart-view gets activated by the Accessibility System.
```swift
func setupAccessibility() {
    isAccessibilityElement = true
    shouldGroupAccessibilityChildren = true

    accessibilityTraits = .button
    accessibilityLabel = "Chart"
    accessibilityHint = "Double tap for audiograph."
}
override func accessibilityActivate() -> Bool {
    // Remove label and hint because they are read when activated. That intefers with audiograph.
    accessibilityLabel = ""
    accessibilityHint = ""

    playAudiograph()
    return true
}

@objc private func playAudiograph() {
    audiograph.play(graphContent: points)
}
```

When the view loses focus, you might want to restore the accessibility attributes:
```swift
override func accessibilityElementDidLoseFocus() {
    // Restore usual accessibility attributes.
    accessibilityLabel = "Chart"
    accessibilityHint = "Double tap for audiograph."
}
```

This project is still young. When you find a better way of playing Audiograph in response to accessibility events *please* update that file or [tell me](https://twitter.com/Klaarname/)!

## Configuration

All of the mentioned customizations need to be set before a call to `play(graphContent:completion:)` starts the playback.

### Playback-Duration
Specifies the amount of seconds the audio should be played. Possible options are:
```swift
public enum PlayingDuration {
    case short
    case recommended
    case long
    case exactly(DispatchTimeInterval)
}
```
* `.short`: The most abbreviated way to present the Audiograph.
* `.recommended`: The best tradeoff between playback duration and maximum length to avoid skipping data points.
* `.long`: The maximum duration. Depending on your input it might produce a great deal of samples which introduces memory pressure.
* `.exactly`: Specify the exact amount of time the playback should take. The longer it takes the more samples need to be stored in memory: *With great power comes great responsibility.*

The above options (with exception of `.exactly`) are **a suggestion only**. The final Audiograph might take longer depending on the input. It is ensured that each segment has enough time to play so that the user is able to hear the difference between two points of the graph.  
However, some data points might be dropped in order to keep the playback duration within a reasonable range.

### Frequencies
The input points are scaled so that they fit in between a minimum and a maximum frequency. The Audiograph's lowest frequency is specified in `minFrequency`, its maximum frequency is stored in `maxFrequency`.  
Those frequencies can be altered depending on the use-case.

### Volume
The volume is configurable by setting `volumeCorrectionFactor`. That factor is applied to the final volume of the sound.  
It might be convenient to specify `0` when running unit tests. If the use-case requires higher volumes, that factor might be set up to a value of `2`.

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

**Andreas Neusüß**

I would love to hear feedback from you. You can send me an email or contact me on [Twitter](https://twitter.com/Klaarname/)! 😊


## License

Audiograph is available under the MIT license. See [the LICENSE file](LICENSE) for more information.
