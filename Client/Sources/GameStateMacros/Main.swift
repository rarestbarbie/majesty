import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main struct Main: CompilerPlugin {
    var providingMacros: [any Macro.Type] = [
        IdentifierMacro.self,
        StringUnionMacro.self,
        StringUnionMacro.Case.self,
    ]
}
