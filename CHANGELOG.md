# Change Log
All notable changes to this project will be documented in this file.
Audiograph adheres to [Semantic Versioning](http://semver.org/).

## Next Release:
- Change of public API in a non-breaking way: 
    - Completion-block can be passed by calling `start`
    - Added a `stop` function to stop playback immediately
    - Added `volumeCorrectionFactor` to give control over the final volume of the Audiograph.
    - Data preprocessing done on separate worker-queue.
- Made the sound stop when the application resigns active
- Connection to audio-engine at the latest possible moment to avoid pausing the users audio.
    
## 0.1.0 (23.12.2019):
- Initial setup of project and documentation
