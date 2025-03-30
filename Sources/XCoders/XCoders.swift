// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

@freestanding(expression)
public macro URL(_ string: StaticString) -> URL = #externalMacro(module: "XCodersMacros", type: "URLMacro")
