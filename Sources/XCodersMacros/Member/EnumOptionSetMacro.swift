//
//  EnumOptionSetMacro.swift
//  XCoders
//
//  Created by Georgi Kuklev on 4.04.25.
//

import SwiftSyntax
import SwiftSyntaxMacros

struct EnumOptionSetMacro: MemberMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
