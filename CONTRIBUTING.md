# Contributing

All contributors are welcome. Please use issues and pull requests to contribute to the project. And update [CHANGELOG.md](CHANGELOG.md) when committing.

## Making a Change

When you commit a change, please add a note to [CHANGELOG.md](CHANGELOG.md).

## Release Process

1. Push a release commit
   1. Update  [CHANGELOG.md](CHANGELOG.md) (by including version number and date of release like `## 0.3.0 (02.02.2020):`)
   2. Update Xcode version number of sample project (`iOS Example.xcworkspace`)
   3. Update the Podspec version number
3. Create release branch with name of version number (don't forget to push it)   
4. Create a GitHub release
   1. Tag the release (like `1.0.5`)
   2. Paste notes from [CHANGELOG.md](CHANGELOG.md)
5. Push the Podspec to CocoaPods
   1. `pod trunk push`
6. Update Carthage
   1. Check if Carthage-Support/Audiograph/ contains changes and is still building (files are only linked there)
   2. Update Carthage-project's Xcode version number in `Carthage-Support/Audiograph/Audiograph.xcodeproj`
