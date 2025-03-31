//
//  PreviewMacro.swift
//  XCoders
//
//  Created by Georgi Kuklev on 31.03.25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct PreviewMacro: DeclarationMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        <#code#>
    }
}
