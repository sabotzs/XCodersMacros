import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct XCodersPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        URLMacro.self,
        PreviewMacro.self,
    ]
}
