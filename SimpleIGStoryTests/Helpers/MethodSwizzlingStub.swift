//
//  MethodSwizzlingStub.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 20/02/2024.
//

import Foundation

final class MethodSwizzlingStub {
    struct MethodPair {
        typealias Pair = (class: AnyClass, method: Selector)
        
        let from: Pair
        let to: Pair
    }
    
    private let instanceMethodPairs: [MethodPair]
    private let classMethodPairs: [MethodPair]
    
    init(instanceMethodPairs: [MethodPair], classMethodPairs: [MethodPair]) {
        self.instanceMethodPairs = instanceMethodPairs
        self.classMethodPairs = classMethodPairs
    }
    
    func swizzled() {
        instanceMethodPairs.forEach { pair in
            method_exchangeImplementations(
                class_getInstanceMethod(pair.from.class, pair.from.method)!,
                class_getInstanceMethod(pair.to.class, pair.to.method)!
            )
        }
        
        classMethodPairs.forEach { pair in
            method_exchangeImplementations(
                class_getClassMethod(pair.from.class, pair.from.method)!,
                class_getClassMethod(pair.to.class, pair.to.method)!
            )
        }
    }
    
    func revertSwizzled() {
        instanceMethodPairs.forEach { pair in
            method_exchangeImplementations(
                class_getInstanceMethod(pair.to.class, pair.to.method)!,
                class_getInstanceMethod(pair.from.class, pair.from.method)!
            )
        }
        
        classMethodPairs.forEach { pair in
            method_exchangeImplementations(
                class_getClassMethod(pair.to.class, pair.to.method)!,
                class_getClassMethod(pair.from.class, pair.from.method)!
            )
        }
    }
}
