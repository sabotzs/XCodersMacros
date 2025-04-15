//
//  TypeErasedMacro.swift
//  XCoders
//
//  Created by Georgi Kuklev on 15.04.25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct TypeErasedMacro {
    let node: AttributeSyntax
    let declaration: DeclSyntaxProtocol
    let context: MacroExpansionContext

    init(node: AttributeSyntax, declaration: DeclSyntaxProtocol, context: MacroExpansionContext) {
        self.node = node
        self.declaration = declaration
        self.context = context
    }

    func expand() throws -> [DeclSyntax] {
        // TODO: Implement
        return []
    }
}

extension TypeErasedMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let macro = TypeErasedMacro(node: node, declaration: declaration, context: context)
        return try macro.expand()
    }
}
