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
        guard let protocolDecl = declaration.as(ProtocolDeclSyntax.self) else {
            return []
        }
        
        let functionDecls = protocolDecl.memberBlock.members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
        
        let propertyDecls = propertyDeclarations(functionDecls: functionDecls)
        let initializerClause = initializerClause(protocolDecl: protocolDecl, functionDecls: functionDecls)
        let confomedFunctionDecls = conformedFunctionDecls(functionDecls: functionDecls)
        
        let typeName = TokenSyntax(stringLiteral: "Any\(protocolDecl.name)")
        let inheritanceClause = InheritanceClauseSyntax {
            InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "\(protocolDecl.name)"))
        }
        let result = StructDeclSyntax(name: typeName, inheritanceClause: inheritanceClause) {
            propertyDecls
            initializerClause
            confomedFunctionDecls
        }
        
        return [DeclSyntax(result)]
    }

    private func conformedFunctionDecls(functionDecls: [FunctionDeclSyntax]) -> [FunctionDeclSyntax] {
        functionDecls.map { functionDecl in
            FunctionDeclSyntax(name: <#T##TokenSyntax#>, signature: <#T##FunctionSignatureSyntax#>, bodyBuilder: <#T##() throws -> CodeBlockItemListSyntax?#>)
        }
    }

    private func propertyDeclarations(functionDecls: [FunctionDeclSyntax]) -> [VariableDeclSyntax] {
        functionDecls.map { functionDecl in
            return VariableDeclSyntax(<#T##bindingSpecifier: Keyword##Keyword#>, name: <#T##PatternSyntax#>, type: <#T##TypeAnnotationSyntax?#>)
        }
    }

    private func initializerClause(
        protocolDecl: ProtocolDeclSyntax,
        functionDecls: [FunctionDeclSyntax]
    ) -> InitializerDeclSyntax {
        let genericType = <#GenericTypeName#>
        let genericParameterClause = GenericParameterClauseSyntax(parametersBuilder: <#T##() throws -> GenericParameterListSyntax#>)
        let signature = FunctionSignatureSyntax(
            parameterClause: FunctionParameterClauseSyntax {
                <#FunctionParameterList#>
            }
        )
        return InitializerDeclSyntax(
            genericParameterClause: <#T##GenericParameterClauseSyntax?#>,
            signature: <#T##FunctionSignatureSyntax#>,
            bodyBuilder: <#T##() throws -> CodeBlockItemListSyntax?#>)
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
