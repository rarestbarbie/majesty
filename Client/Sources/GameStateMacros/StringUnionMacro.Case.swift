import SwiftSyntax
import SwiftSyntaxMacros

extension StringUnionMacro {
    struct Case {
        let name: String
        let type: TypeSyntax?
        let discriminant: Unicode.Scalar
    }
}
extension StringUnionMacro.Case: PeerMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingPeersOf _: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
