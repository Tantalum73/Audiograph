# Contributing

All contributors are welcome. Please use issues and pull requests to contribute to the project. And update [CHANGELOG.md](CHANGELOG.md) when committing.

## Making a Change

When you commit a change, please add a note to [CHANGELOG.md](CHANGELOG.md).

## Release Process

1. Push a release commit
    1. Update  [CHANGELOG.md](CHANGELOG.md) (by including version number and date of release like `## 0.3.0 (02.02.2020):`)
   2. Update Xcode version number
   3. Update the Podspec version number
2. Create a GitHub release
   1. Tag the release (like `1.0.5`)
   2. Paste notes from [CHANGELOG.md](CHANGELOG.md)
3. Push the Podspec to CocoaPods
   1. `pod trunk push`
4. Create Carthage binaries
   1. `carthage build --no-skip-current`
   2. `carthage archive Audiograph`
   3. Add to the GitHub release
