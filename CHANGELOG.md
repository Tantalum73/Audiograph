# Change Log
All notable changes to this project will be documented in this file.
Audiograph adheres to [Semantic Versioning](http://semver.org/).

## Next Release:

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
