import SwiftSyntax
import SwiftSyntaxMacros

/// Implements the `#assert` freestanding macro.
public struct AssertMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard
        let condition: ExprSyntax = node.arguments.first?.expression,
        let message: ExprSyntax = node.arguments.last?.expression else {
            fatalError("compiler bug: macro requires two arguments")
        }

        return """
        _ = if true {
            #if TESTABLE
            if \(condition) { () } else { { fatalError($0) } (\(message)) as Never }
            #else
            ()
            #endif
        } else {
            ()
        }
        """
    }
}
