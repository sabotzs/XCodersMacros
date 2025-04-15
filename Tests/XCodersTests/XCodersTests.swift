import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(XCodersMacros)
@testable import XCodersMacros

let testMacros: [String: Macro.Type] = [
    "TypeErased": TypeErasedMacro.self,
]
#endif

final class XCodersTests: XCTestCase {

}
