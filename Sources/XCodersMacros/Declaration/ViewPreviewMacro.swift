//
//  ViewPreviewMacro.swift
//  XCoders
//
//  Created by Georgi Kuklev on 31.03.25.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct ViewPreviewMacro: DeclarationMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws(ViewPreviewMacroError) -> [DeclSyntax] {
        guard let location = context.location(of: node) else {
            fatalError("can't find file name")
        }

        let content: CodeBlockItemListSyntax? = if let trailingClosure = node.trailingClosure?.statements {
            trailingClosure
        } else if let argument = node.arguments.first?.expression.as(ClosureExprSyntax.self)?.statements, node.arguments.count == 1 {
            argument
        } else {
            nil
        }

        guard let content else {
            throw .notClosure
        }

        return [
            """
            private struct __ViewPreview$: PreviewProvider {
                var file: String {
                    \(location.file)
                }

                var line: Int {
                    \(location.line)
                }

                var column: Int {
                    \(location.column)
                }

                static var previews: some View {
                    \(content)
                }
            }
            """
        ]
    }
}

enum ViewPreviewMacroError: Error, CustomStringConvertible {
    case notClosure

    var description: String {
        switch self {
        case .notClosure: "The argument is expected to be a closure"
        }
    }
}

//private struct ContentView_Preview: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

//#ViewPreview {
//    ContentView()
//}

//@freestanding(declaration)
//public macro Preview(
//    _ name: String? = nil,
//    @ViewBuilder body: @escaping @MainActor () -> any View
//) = #externalMacro(module: "PreviewsMacros", type: "SwiftUIView")

//struct $s4test0022ContentViewswift_tiAIefMX27_0_33_D8BD9D96E9F69648B19272822CAD992ALl7PreviewfMf_15PreviewRegistryfMu_: DeveloperToolsSupport.PreviewRegistry {
//    static var fileID: String {
//        "test/ContentView.swift"
//    }
//    static var line: Int {
//        28
//    }
//    static var column: Int {
//        1
//    }
//
//    static func makePreview() throws -> DeveloperToolsSupport.Preview {
//        DeveloperToolsSupport.Preview {
//            func __b_buildView(@SwiftUI.ViewBuilder body: () -> any SwiftUI.View) -> any SwiftUI.View {
//                body()
//            }
//            return __b_buildView {
//                ContentView()
//            }
//        }
//    }
//}
