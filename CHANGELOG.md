# Change Log
All notable changes to this project will be documented in this file.
Audiograph adheres to [Semantic Versioning](http://semver.org/).

## Next Release:
- Completion Utterance is now only read once, even though the autiograph was started multiple times.
- Setting diagnostics output to false by default.
- Now it's possible to pass in data that contains multiple elements at the same x-position (which translates into time).

## 0.4.0 (29.03.2020):
- Refactored scaling timestamps in DataProcessor.
- Fixed potential heap overflow.
- Fixed a bug where completion block was not called on main queue every time.
- Introducing smoothing: the data is pre-processed to contain less spikes, `SmoothingOption` and `smoothing` were added to public API.

## 0.3.1 (03.02.2020):
- Improved audio experience by using Double instead of Float32.
- Fixed a bug where the playback in .recommended duration only took the minimum amount of time possible.
- Not speaking completion phrase when `volumeCorrectionFactor` is set to 0.

## 0.3.0 (02.02.2020):
- Introduction of `completionIndicationUtterance` to indicate verbally that Audiograph has finished.
- `AudiographPlayable` and `AudiographProvider` to make views and objects poviders of chart data.
- `AudiographLocalizations` to gather all the strings that need to be provided by the application.
- `Audiograph.createCustomAccessibilityAction(using: AudiographProvider)` and  `Audiograph.createCustomAccessibilityAction(for: AudiographPlayable)` to create an `UIAccessibilityCustomAction` that can directly be used as trigger for Audiograph in the view.
- Almost automatic setup of accessibility when using one of the mentioned function, even with playback cancellation when the view lost its focus.
- Calling `stop` also stops the completion-utterance.

## 0.2.0 (07.01.2020):
- Change of public API in a non-breaking way:
    - Completion-block can be passed by calling `start`
    - Added a `stop` function to stop playback immediately
    - Added `volumeCorrectionFactor` to give control over the final volume of the Audiograph.
    - Data preprocessing done on separate worker-queue.
- Made the sound stop when the application resigns active
- Connection to audio-engine at the latest possible moment to avoid pausing the users audio.

## 0.1.0 (23.12.2019):
- Initial setup of project and documentation
