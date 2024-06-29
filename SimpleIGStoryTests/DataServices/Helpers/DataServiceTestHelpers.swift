//
//  DataServiceTestHelpers.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 08/02/2024.
//

import Foundation

func validJSONURL(currentClass: AnyClass, file: StaticString = #filePath) -> URL {
    bundle(currentClass: currentClass).url(forResource: "valid.json", withExtension: nil)!
}

func bundle(currentClass: AnyClass) -> Bundle {
    Bundle(for: currentClass)
}
