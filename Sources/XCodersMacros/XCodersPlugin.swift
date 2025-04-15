//
//  XCodersPlugin.swift
//  XCoders
//
//  Created by Georgi Kuklev on 15.04.25.
//

import SwiftSyntaxMacros
import SwiftCompilerPlugin

@main
struct XCodersPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        TypeErasedMacro.self,
    ]
}
