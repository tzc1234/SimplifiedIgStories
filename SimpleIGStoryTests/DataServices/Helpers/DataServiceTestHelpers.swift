//
//  DataServiceTestHelpers.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 08/02/2024.
//

import Foundation

typealias JSON = [String: Any]

func validJsonURL(currentClass: AnyClass) -> URL {
    Bundle(for: currentClass).url(forResource: "valid.json", withExtension: nil)!
}

func avatarURLFor(_ avatar: String) -> URL {
    Bundle.main.url(forResource: avatar, withExtension: "jpg")!
}

func resourceURLFor(_ resource: String, type: String) -> URL {
    Bundle.main.url(forResource: resource, withExtension: type == "video" ? "mp4" : "jpg")!
}
