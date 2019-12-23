# Contributing

All contributors are welcome. Please use issues and pull requests to contribute to the project. And update [CHANGELOG.md](CHANGELOG.md) when committing.

## Making a change

When you commit a change, please add a note to [CHANGELOG.md](CHANGELOG.md).

## Release process

1. Push a release commit
   1. Create a new Master section at the top
   2. Rename the old Master section like:
          ## [1.0.5](https://github.com/Tantalum73/Audiograph/releases/tag/1.0.5)
          Released on 2019-10-15.
   3. Update the Podspec version number
2. Create a GitHub release
   1. Tag the release (like `1.0.5`)
   2. Paste notes from [CHANGELOG.md](CHANGELOG.md)
3. Push the Podspec to CocoaPods
   1. `pod trunk push`
4. Create Carthage binaries
   1. `carthage build --no-skip-current`
   2. `carthage archive __PROJECT_NAME__`
   3. Add to the GitHub release
