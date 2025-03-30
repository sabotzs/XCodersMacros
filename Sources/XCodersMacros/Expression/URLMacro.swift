//
//  URLMacro.swift
//  XCoders
//
//  Created by Georgi Kuklev on 26.03.25.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct URLMacro: ExpressionMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let argument = node.arguments.first?.expression.as(StringLiteralExprSyntax.self),
              case .stringSegment(let literal)? = argument.segments.first
        else {
            fatalError("compiler error")
        }
        guard let _ = URL(string: literal.content.text) else {
            throw URLMacroError.invalidURL
        }
        return "URL(string: \(argument))!"
    }
}

enum URLMacroError: String, Error {
    case invalidURL
}
