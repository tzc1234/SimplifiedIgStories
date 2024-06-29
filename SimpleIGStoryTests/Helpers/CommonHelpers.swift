//
//  CommonHelpers.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 19/02/2024.
//

import Foundation

func anyNSError() -> NSError {
    NSError(domain: "any", code: 0)
}

func anyVideoURL() -> URL {
    URL(string: "file://any-video.mp4")!
}

func anyImageURL() -> URL {
    URL(string: "file://any-image.jpg")!
}
