# Simple IG Story
A simple version of IG story, this demo app is my SwiftUI study record.
**WIP: Refactoring this 2 years ago app.**

## Screenshots
<img src="https://github.com/tzc1234/SimplifiedIgStories/blob/main/Screenshots/preview.gif" alt="preview" width="256" height="455"/> <img src="https://github.com/tzc1234/SimplifiedIgStories/blob/main/Screenshots/preview2.jpg" alt="preview2" width="256" height="455"/> <img src="https://github.com/tzc1234/SimplifiedIgStories/blob/main/Screenshots/preview3.jpg" alt="preview3" width="256" height="455"/>

## Technologies
1. SwiftUI
2. Combine
3. AVFoundation
4. XCTest
5. Async/await

## Update History
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