// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftUI

@freestanding(expression)
public macro URL(_ string: StaticString) -> URL = #externalMacro(module: "XCodersMacros", type: "URLMacro")

@freestanding(declaration, names: arbitrary)
public macro ViewPreview(@ViewBuilder content: @escaping () -> any View) = #externalMacro(module: "XCodersMacros", type: "ViewPreviewMacro")
