import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

enum ApplicationStroageMacroDiagnostic {
    case mutilpleDecls
    case declNotSupport
    case paramMiss
}

extension ApplicationStroageMacroDiagnostic: DiagnosticMessage {
    var message: String {
        switch self {
        case .mutilpleDecls:
            return "'var' declarations with multiple variables cannot have explicit getters/setters"
        case .declNotSupport:
            return "Annotaion only support 'var' declarations."
        case .paramMiss:
            return "Anootation miss the parameter."
        }
    }
    
    var diagnosticID: SwiftDiagnostics.MessageID {
        switch self {
        case .mutilpleDecls:
            return MessageID(domain: "ApplicationStroageMacroDiagnostic", id: "mutilpleDecls")
        case .declNotSupport:
            return MessageID(domain: "ApplicationStroageMacroDiagnostic", id: "declNotSupport")
        case .paramMiss:
            return MessageID(domain: "ApplicationStroageMacroDiagnostic", id: "paramMiss")
        }
    }
    
    var severity: SwiftDiagnostics.DiagnosticSeverity {
        switch self {
        case .mutilpleDecls:
            return .error
        case .declNotSupport:
            return .error
        case .paramMiss:
            return .error
        }
    }
    
    
}

public struct ApplicationStroageMacro {
    
}

extension ApplicationStroageMacro: PeerMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        
        let plugin = try ApplicationStroageMacroHelper(node: node, declaration: declaration, context: context)
        
        return plugin.genPeerMacro()
    }
    
    
}

extension ApplicationStroageMacro: AccessorMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        
        let plugin = try ApplicationStroageMacroHelper(node: node, declaration: declaration, context: context)
        
        return plugin.genAccessor()
    }
    
}

public struct ApplicationStroageMacroHelper {
    var node: SwiftSyntax.AttributeSyntax
    var declaration: VariableDeclSyntax
    var property: StringSegmentSyntax
    
    
    init(node: SwiftSyntax.AttributeSyntax, declaration: some DeclSyntaxProtocol, context: some MacroExpansionContext) throws {
        guard
            let varDecls = declaration.as(VariableDeclSyntax.self)
        else {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: node._syntaxNode, message: ApplicationStroageMacroDiagnostic.declNotSupport)
            ])
        }
        
        guard varDecls.bindings.count == 1 else {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: node._syntaxNode, message: ApplicationStroageMacroDiagnostic.mutilpleDecls)
            ])
        }
        
        guard case let .argumentList(arguments) = node.argument,
              let firstElement = arguments.first,
              let stringLiteral = firstElement.expression.as(StringLiteralExprSyntax.self),
              stringLiteral.segments.count == 1,
              case let .stringSegment(wrapperName)? = stringLiteral.segments.first else {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: node._syntaxNode, message: ApplicationStroageMacroDiagnostic.paramMiss)
            ])
        }
    
        
        self.node = node
        self.declaration = varDecls
        self.property = wrapperName
    }
}


extension ApplicationStroageMacroHelper {
    private func StorageKey(_ suffix: String) -> String {
        return "\(suffix)StorageKey"
    }
    
    public func getVarDeclClass() -> String {
        
        return self.declaration.bindings
            .compactMap {$0.typeAnnotation}
            .map {$0.type.as(SimpleTypeIdentifierSyntax.self)}
            .compactMap {$0?.name.text}
            .first!
    }
    
    public func genPeerMacro() -> [SwiftSyntax.DeclSyntax] {
        let cls = getVarDeclClass()
        
        return [
            "struct \(raw: StorageKey(cls)): StorageKey { public typealias Value = \(raw: cls) }"
        ]
    }
    
    public func genAccessor() -> [AccessorDeclSyntax] {
        let cls = getVarDeclClass()
        let property = property.content.text
        
        return [
            """
            get {
                guard let client = self.\(raw: property)[\(raw: StorageKey(cls)).self] else {
                    fatalError("\(raw: cls) not setup.")
                }
                return client
            }
            """,
            """
            set {
                self.\(raw: property).set(\(raw: StorageKey(cls)).self, to: newValue)
            }
            """
        ]
    }
}

@main
struct MarcoKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ApplicationStroageMacro.self,
    ]
}
