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
    func test_macroExpansion_withVoidToVoidFunction_shouldExpand() throws {
#if canImport(XCodersMacros)
        assertMacroExpansion(
            """
            @TypeErased
            protocol Printer {
                func print()
            }
            """,
            expandedSource:
            """
            protocol Printer {
                func print()
            }
            
            struct AnyPrinter : Printer {
                private let _print: () -> Void
            
                init<__macro_local_7PrinterfMu_: Printer >(_ printer: __macro_local_7PrinterfMu_) {
                    self._print = printer.print
                }
            
                func print() {
                    _print()
                }
            }
            """,
            macros: testMacros)
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}
