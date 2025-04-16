//
//  TypeErasedMacro.swift
//  XCoders
//
//  Created by Georgi Kuklev on 15.04.25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

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
            let diagnostic = Diagnostic(node: declaration, message: TypeErasedDiagnosticMessage.notProtocol)
            context.diagnose(diagnostic)
            return []
        }
        
        let functionDecls = protocolDecl.memberBlock.members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
        
        do {
            try staticCheck(functionDecls: functionDecls)
        } catch {
            return []
        }
        
        let associatedTypeDecls = protocolDecl.memberBlock.members
            .compactMap { $0.decl.as(AssociatedTypeDeclSyntax.self) }
        
        let propertyDecls = propertyDeclarations(functionDecls: functionDecls)
        let initializerDecl = initializerDecl(protocolDecl: protocolDecl, functionDecls: functionDecls, associatedTypeDecls: associatedTypeDecls)
        let confomedFunctionDecls = conformedFunctionDecls(functionDecls: functionDecls)
        
        let typeName = TokenSyntax(stringLiteral: "Any\(protocolDecl.name)")
        let genericParameterClause = genericParameterClause(associatedTypeDecls: associatedTypeDecls)
        let inheritanceClause = InheritanceClauseSyntax {
            InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "\(protocolDecl.name)"))
        }
        let result = typeDeclaration(
            protocolDecl: protocolDecl,
            typeName: typeName,
            genericParameterClause: genericParameterClause,
            inheritanceClause: inheritanceClause,
            propertyDecls: propertyDecls,
            initializerDecl: initializerDecl,
            conformedFunctionDecls: confomedFunctionDecls
        )
        
        return [result]
    }

    private func staticCheck(functionDecls: [FunctionDeclSyntax]) throws {
        let staticFunctions = functionDecls.compactMap { functionDecl in
            let staticModifierIndex = functionDecl.modifiers.firstIndex { $0.name.tokenKind == .keyword(.static) }
            if let staticModifierIndex {
                return (functionDecl: functionDecl, staticModifierIndex: staticModifierIndex)
            }
            return nil
        }
        guard !staticFunctions.isEmpty else {
            return
        }
        let diagnostic = Diagnostic(
            node: staticFunctions.first!.functionDecl,
            message: TypeErasedDiagnosticMessage.staticFunction,
            fixIts: staticFunctions.map {
                var newNode = $0.functionDecl
                newNode.modifiers.remove(at: $0.staticModifierIndex)
                return .replace(
                    message: TypeErasedFixItMessage(message: "Remove static keyword for function \($0.functionDecl.name)"),
                    oldNode: $0.functionDecl,
                    newNode: newNode
                )
            }
        )
        context.diagnose(diagnostic)
        throw ImplementationError.staticCheck
    }

    private func typeDeclaration(
        protocolDecl: ProtocolDeclSyntax,
        typeName: TokenSyntax,
        genericParameterClause: GenericParameterClauseSyntax?,
        inheritanceClause: InheritanceClauseSyntax,
        propertyDecls: [VariableDeclSyntax],
        initializerDecl: InitializerDeclSyntax,
        conformedFunctionDecls: [FunctionDeclSyntax]
    ) -> DeclSyntax {
        let hasClassConstraint = protocolDecl.inheritanceClause?.inheritedTypes
            .contains { $0.type.description.trimmingCharacters(in: .whitespaces) == "AnyObject" } ?? false
        
        if hasClassConstraint {
            let classDecl = ClassDeclSyntax(name: typeName, genericParameterClause: genericParameterClause, inheritanceClause: inheritanceClause) {
                propertyDecls
                initializerDecl
                conformedFunctionDecls
            }
            return DeclSyntax(classDecl)
        }
        
        let structDecl = StructDeclSyntax(name: typeName, genericParameterClause: genericParameterClause, inheritanceClause: inheritanceClause) {
            propertyDecls
            initializerDecl
            conformedFunctionDecls
        }
        return DeclSyntax(structDecl)
    }

    private func genericParameterClause(associatedTypeDecls: [AssociatedTypeDeclSyntax]) -> GenericParameterClauseSyntax? {
        guard !associatedTypeDecls.isEmpty else {
            return nil
        }
        return GenericParameterClauseSyntax {
            associatedTypeDecls.map { associatedTypeDecl in
                if let inheritanceClause = associatedTypeDecl.inheritanceClause {
                    let inheritedTypes = CompositionTypeElementListSyntax {
                        inheritanceClause.inheritedTypes.map { inheritedType in
                            CompositionTypeElementSyntax(type: inheritedType.type)
                        }
                    }
                    return GenericParameterSyntax(
                        name: associatedTypeDecl.name,
                        colon: .colonToken(),
                        inheritedType: CompositionTypeSyntax(elements: inheritedTypes)
                    )
                }
                return GenericParameterSyntax(name: associatedTypeDecl.name)
            }
        }
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
        functionDecls: [FunctionDeclSyntax],
        associatedTypeDecls: [AssociatedTypeDeclSyntax]
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
        let genericWhereClause: GenericWhereClauseSyntax? = if !associatedTypeDecls.isEmpty {
            GenericWhereClauseSyntax {
                associatedTypeDecls.map { associatedTypeDecl in
                    let requirement = SameTypeRequirementSyntax(
                        leftType: TypeSyntax(stringLiteral: "\(genericType).\(associatedTypeDecl.name)"),
                        equal: .binaryOperator("=="),
                        rightType: TypeSyntax(stringLiteral: "\(associatedTypeDecl.name)"))
                    return GenericRequirementSyntax(requirement: .sameTypeRequirement(requirement))
                }
            }
        } else {
            nil
        }
        return InitializerDeclSyntax(
            leadingTrivia: .newlines(2),
            genericParameterClause: genericParameterClause,
            signature: signature,
            genericWhereClause: genericWhereClause
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

enum ImplementationError: Error {
    case staticCheck
}

enum TypeErasedDiagnosticMessage: DiagnosticMessage {
    case notProtocol
    case staticFunction

    var message: String {
        switch self {
        case .notProtocol:
            return "Macro @TypeErased can be applied only to protocols."
        case .staticFunction:
            return "@TypeErased protocols can't contain static functions"
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "com.type-erased-macro", id: message)
    }
    
    var severity: DiagnosticSeverity {
        switch self {
        case .notProtocol:
            return .error
        case .staticFunction:
            return .error
        }
    }
}

struct TypeErasedFixItMessage: FixItMessage {
    var message: String
    
    var fixItID: MessageID {
        MessageID(domain: "com.type-erased-macro", id: message)
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
