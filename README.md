# Simple IG Story [![ios-ci](https://github.com/tzc1234/SimplifiedIgStories/actions/workflows/ios-ci.yaml/badge.svg)](https://github.com/tzc1234/SimplifiedIgStories/actions/workflows/ios-ci.yaml)
A simple version of IG story, this demo app is my SwiftUI study record.

## Screenshots
<img src="https://github.com/tzc1234/SimplifiedIgStories/blob/main/Screenshots/preview.gif" alt="preview" width="256" height="455"/> <img src="https://github.com/tzc1234/SimplifiedIgStories/blob/main/Screenshots/preview2.jpg" alt="preview2" width="256" height="455"/> <img src="https://github.com/tzc1234/SimplifiedIgStories/blob/main/Screenshots/preview3.jpg" alt="preview3" width="256" height="455"/>

## Retrospective
Although the refactoring is still ongoing, I would like to write down some of my reflections at the moment.

#### Unit tests
There were only a few parts of view models covered by unit tests 2 years ago. As an advocate of automated tests, it's a shame! I've already added back/update unit tests for view models and their collaborators, to improve the reliability of this app.

However, there is no unit tests coverage for all the SwiftUI views, because no testing mechanism officially provided by Apple. And I don't want to rely on 3rd party dependencies, for example, I've replaced the dependency of 3rd party `SwiftyCam` to my own AVFoundation components before. My goal is to keep this app simple and pure.

Also, although the ideal way is using the real stuff for unit tests, because of the real AVfoundation framework is not testable in iOS simulator (simulator has no camera and mic.), all the tests written for AVFoundation components are by subclassing/method swizzling, mocking AVFoundation functions. This is the trade-off, it has the risk that the behaviours of those "mocking functions" may not be correct in the future iOS version, but this does enable testability.

#### Separation of the animation logic
Before, all the animation code was mixed with others in view models. I've done the separation, view models focus on other actions such as: image/video file management, and animation handlers are responsible for animation logic. Separation of concerns, keeping each component simple.

#### Compose views in composition root
There are views composed in `SimplifiedIgStoriesApp`, aka composition root. Before, the view had to "carry" every dependency which their child view needed only, or create the dependency the view did not need by itself.
This is an important move, it does enable the possibility to inject their collaborators directly depending on the view's need without caring of the view hierarchy.

## Technologies
1. SwiftUI
2. Combine
3. AVFoundation
4. XCTest
5. Async/await

## Update History
#### 04/07/2024
1. Add `StoryPreviewViewModel`
2. Add unit tests for `StoryPreviewViewModel`

#### 03/07/2024
1. Refactor `StoryCameraViewModel`
2. Update unit tests for `StoryCameraViewModel`

#### 25/03/2024
1. Extract animation logic from `StoriesViewModel` to `StoriesAnimationHandler`
2. Remove unnecessary `StoryViewModel`
3. Perform portion actions in a portion level `StoryPortionViewModel`
4. Add unit tests for `StoryPortionViewModel`, `StoriesAnimationHandler` and `StoryAnimationHandler`
5. Compose views and their collaborators in `SimplifiedIgStoriesApp`, aka composition root. Unlock the possibility to do dependency injection directly, without care of the view hierarchy.

#### 18/03/2024
1. Cover most of the code in `StoriesViewModel` by unite tests
2. Inject `StoriesViewModel` into `HomeView`
3. Extract animation logic from `StoryViewModel` to `StoryAnimationHandler`

#### 20/02/2024
1. Add unit tests

#### 25/07/2022:
1. Refactored some animation logic.
2. More tests.

#### 19/06/2022:
1. Use my own AVFoundation manager class instead of SwiftyCam package.

#### 27/04/2022:
1. Add unit test for `StoriesModelView`.

#### 20/03/2022:
1. Merge combine branch to main.
2. Add SwiftyCam by package from my forked [combine-framework branch](https://github.com/tzc1234/SwiftyCam/tree/combine-framework).

#### 17/03/2022:
1. Start a new branch for studying Combine Framework.

#### 14/03/2022:
1. Handle camera and microphone permission.

#### 12/03/2022:
1. Support removing current user story.

#### 10/03/2022:
1. Support playing video type story.
2. Support taking photo and recording video for your story by [SwiftyCam](https://github.com/Awalz/SwiftyCam).
3. Save your photo/video to album.