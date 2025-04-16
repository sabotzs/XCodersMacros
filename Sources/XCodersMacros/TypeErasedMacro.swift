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
        let initializerDecl = initializerDecl(protocolDecl: protocolDecl, functionDecls: functionDecls)
        let confomedFunctionDecls = conformedFunctionDecls(functionDecls: functionDecls)
        
        let typeName = TokenSyntax(stringLiteral: "Any\(protocolDecl.name)")
        let inheritanceClause = InheritanceClauseSyntax {
            InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "\(protocolDecl.name)"))
        }
        let result = typeDeclaration(
            protocolDecl: protocolDecl,
            typeName: typeName,
            inheritanceClause: inheritanceClause,
            propertyDecls: propertyDecls,
            initializerDecl: initializerDecl,
            conformedFunctionDecls: confomedFunctionDecls
        )
        
        return [result]
    }
    private func typeDeclaration(
        protocolDecl: ProtocolDeclSyntax,
        typeName: TokenSyntax,
        inheritanceClause: InheritanceClauseSyntax,
        propertyDecls: [VariableDeclSyntax],
        initializerDecl: InitializerDeclSyntax,
        conformedFunctionDecls: [FunctionDeclSyntax]
    ) -> DeclSyntax {
        let hasClassConstraint = protocolDecl.inheritanceClause?.inheritedTypes
            .contains { $0.type.description.trimmingCharacters(in: .whitespaces) == "AnyObject" } ?? false
        
        if hasClassConstraint {
            let classDecl = ClassDeclSyntax(name: typeName, inheritanceClause: inheritanceClause) {
                propertyDecls
                initializerDecl
                conformedFunctionDecls
            }
            return DeclSyntax(classDecl)
        }
        
        let structDecl = StructDeclSyntax(name: typeName, inheritanceClause: inheritanceClause) {
            propertyDecls
            initializerDecl
            conformedFunctionDecls
        }
        return DeclSyntax(structDecl)
    }

    private func propertyDeclarations(functionDecls: [FunctionDeclSyntax]) -> [VariableDeclSyntax] {
        let modifiers = DeclModifierListSyntax {
            DeclModifierSyntax(name: .keyword(.private))
        }
        return functionDecls.map { functionDecl in
            let inputType = TupleTypeElementListSyntax {
                functionDecl.signature.parameterClause.parameters.map { parameter in
                    TupleTypeElementSyntax(type: parameter.type)
                }
            }
            let returnClause = functionDecl.signature.returnClause ?? ReturnClauseSyntax(type: TypeSyntax(stringLiteral: "Void"))
            let functionType = FunctionTypeSyntax(
                parameters: inputType,
                effectSpecifiers: TypeEffectSpecifiersSyntax(
                    asyncSpecifier: functionDecl.signature.effectSpecifiers?.asyncSpecifier,
                    throwsClause: functionDecl.signature.effectSpecifiers?.throwsClause
                ),
                returnClause: returnClause)
            return VariableDeclSyntax(
                modifiers: modifiers,
                .let,
                name: PatternSyntax(stringLiteral: "_\(functionDecl.name)"),
                type: TypeAnnotationSyntax(type: functionType))
        }
    }

    private func initializerDecl(
        protocolDecl: ProtocolDeclSyntax,
        functionDecls: [FunctionDeclSyntax]
    ) -> InitializerDeclSyntax {
        let genericType = context.makeUniqueName(protocolDecl.name.text)
        let argumentName = TokenSyntax(stringLiteral: protocolDecl.name.text.lowercased())
        let genericParameterClause = GenericParameterClauseSyntax {
            GenericParameterSyntax(name: genericType, colon: .colonToken(), inheritedType: TypeSyntax(stringLiteral: "\(protocolDecl.name)"))
        }
        let signature = FunctionSignatureSyntax(
            parameterClause: FunctionParameterClauseSyntax {
                FunctionParameterSyntax(firstName: .wildcardToken(), secondName: argumentName, type: TypeSyntax(stringLiteral: "\(genericType)"))
            }
        )
        return InitializerDeclSyntax(
            leadingTrivia: .newlines(2),
            genericParameterClause: genericParameterClause,
            signature: signature
        ) {
            functionDecls.map { functionDecl in
                CodeBlockItemSyntax(item: .expr("self._\(functionDecl.name) = \(argumentName).\(functionDecl.name)"))
            }
        }
    }

    private func conformedFunctionDecls(functionDecls: [FunctionDeclSyntax]) -> [FunctionDeclSyntax] {
        functionDecls.map { functionDecl in
            FunctionDeclSyntax(leadingTrivia: .newlines(2), name: functionDecl.name, signature: functionDecl.signature) {
                functionCall(functionDecl: functionDecl)
            }
        }
    }
    
    private func functionCall(functionDecl: FunctionDeclSyntax) -> ExprSyntaxProtocol {
        var result: ExprSyntaxProtocol = FunctionCallExprSyntax(
            calledExpression: ExprSyntax(stringLiteral: "_\(functionDecl.name)"),
            leftParen: .leftParenToken(),
            rightParen: .rightParenToken()
        ) {
            functionDecl.signature.parameterClause.parameters.map {
                LabeledExprSyntax(expression: ExprSyntax(stringLiteral: "\($0.secondName ?? $0.firstName)"))
            }
        }
        if functionDecl.signature.effectSpecifiers?.asyncSpecifier != nil {
            result = AwaitExprSyntax(expression: result)
        }
        if functionDecl.signature.effectSpecifiers?.throwsClause != nil {
            result = TryExprSyntax(expression: result)
        }
        return result
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
