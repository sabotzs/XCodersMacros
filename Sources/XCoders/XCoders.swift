// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftUI

@freestanding(expression)
public macro URL(_ string: StaticString) -> URL = #externalMacro(module: "XCodersMacros", type: "URLMacro")

@freestanding(declaration)
public macro ViewPreview<Content: View>(@ViewBuilder content: @escaping () -> Content) = #externalMacro(module: "XCodersMacros", type: "PreviewMacro")
