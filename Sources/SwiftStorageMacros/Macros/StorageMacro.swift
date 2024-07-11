//
//  StorageMacro.swift
//
//
//  Created by Keisuke Chinone on 2024/07/07.
//


import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftOperators
import SwiftSyntaxBuilder
import Observation

public struct StorageMacro {
    static let observationModuleName = "Observation"
    
    static let observationConformanceName = "Observable"
    
    static var observationQualifiedConformanceName: String {
        return "\(observationModuleName).\(observationConformanceName)"
    }
    
    static var observationStorageConformanceType: TypeSyntax {
        "\(raw: observationQualifiedConformanceName)"
    }
    
    
    static let moduleName = "SwiftStorage"
    
    static let conformanceName = "Storage"
    
    static var qualifiedConformanceName: String {
        return "\(moduleName).\(conformanceName)"
    }
    
    static var storageConformanceType: TypeSyntax {
        "\(raw: qualifiedConformanceName)"
    }
    
    
    static let registrarTypeName = "ObservationRegistrar"
    
    static var qualifiedRegistrarTypeName: String {
        return "Observation.\(registrarTypeName)"
    }
    
    
    static let localStoragePropertyMacroName = "LocalStorageProperty"
    
    static let observationTrackedMacroName = "ObservationTracked"
    
    static let transientMacroName = "Transient"
    
    static let observationIgnoredMacroName = "ObservationIgnored"
    
    static let attributeMacroName = "Attribute"
    
    static let registrarVariableName = "_$observationRegistrar"
    
    static func registrarVariable(_ storageType: TokenSyntax) -> DeclSyntax {
        return
      """
      @\(raw: transientMacroName) private let \(raw: registrarVariableName) = \(raw: qualifiedRegistrarTypeName)()
      """
    }
    
    static func accessFunction(_ storageType: TokenSyntax) -> DeclSyntax {
        return
      """
      internal nonisolated func access<Member>(
      keyPath: KeyPath<\(storageType), Member>
      ) {
      \(raw: registrarVariableName).access(self, keyPath: keyPath)
      }
      """
    }
    
    static func withMutationFunction(_ storageType: TokenSyntax) -> DeclSyntax {
        return
      """
      internal nonisolated func withMutation<Member, MutationResult>(
      keyPath: KeyPath<\(storageType), Member>,
      _ mutation: () throws -> MutationResult
      ) rethrows -> MutationResult {
      try \(raw: registrarVariableName).withMutation(of: self, keyPath: keyPath, mutation)
      }
      """
    }
    
    static func classNameVariable(_ name: String) -> DeclSyntax {
        return
      """
      @\(raw: transientMacroName) private let className = "\(raw: name)"
      """
    }
    
    static var ignoredAttribute: AttributeSyntax {
        AttributeSyntax(
            leadingTrivia: .space,
            atSign: .atSignToken(),
            attributeName: IdentifierTypeSyntax(name: .identifier(transientMacroName)),
            trailingTrivia: .space
        )
    }
}

struct ObservationDiagnostic: DiagnosticMessage {
    enum ID: String {
        case invalidApplication = "invalid type"
        case missingInitializer = "missing initializer"
    }
    
    var message: String
    var diagnosticID: MessageID
    var severity: DiagnosticSeverity
    
    init(message: String, diagnosticID: SwiftDiagnostics.MessageID, severity: SwiftDiagnostics.DiagnosticSeverity = .error) {
        self.message = message
        self.diagnosticID = diagnosticID
        self.severity = severity
    }
    
    init(message: String, domain: String, id: ID, severity: SwiftDiagnostics.DiagnosticSeverity = .error) {
        self.message = message
        self.diagnosticID = MessageID(domain: domain, id: id.rawValue)
        self.severity = severity
    }
}

extension DiagnosticsError {
    init<S: SyntaxProtocol>(syntax: S, message: String, domain: String = "Strage", id: ObservationDiagnostic.ID, severity: SwiftDiagnostics.DiagnosticSeverity = .error) {
        self.init(diagnostics: [
            Diagnostic(node: Syntax(syntax), message: ObservationDiagnostic(message: message, domain: domain, id: id, severity: severity))
        ])
    }
}

extension DeclModifierListSyntax {
    func privatePrefixed(_ prefix: String) -> DeclModifierListSyntax {
        let modifier: DeclModifierSyntax = DeclModifierSyntax(name: "private", trailingTrivia: .space)
        return [modifier] + filter {
            switch $0.name.tokenKind {
            case .keyword(let keyword):
                switch keyword {
                case .fileprivate: fallthrough
                case .private: fallthrough
                case .internal: fallthrough
                case .package: fallthrough
                case .public:
                    return false
                default:
                    return true
                }
            default:
                return true
            }
        }
    }
    
    init(keyword: Keyword) {
        self.init([DeclModifierSyntax(name: .keyword(keyword))])
    }
}

extension TokenSyntax {
    func privatePrefixed(_ prefix: String) -> TokenSyntax {
        switch tokenKind {
        case .identifier(let identifier):
            return TokenSyntax(.identifier(prefix + identifier), leadingTrivia: leadingTrivia, trailingTrivia: trailingTrivia, presence: presence)
        default:
            return self
        }
    }
}

extension PatternBindingListSyntax {
    func privatePrefixed(_ prefix: String) -> PatternBindingListSyntax {
        var bindings = self.map { $0 }
        for index in 0..<bindings.count {
            let binding = bindings[index]
            if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                bindings[index] = PatternBindingSyntax(
                    leadingTrivia: binding.leadingTrivia,
                    pattern: IdentifierPatternSyntax(
                        leadingTrivia: identifier.leadingTrivia,
                        identifier: identifier.identifier.privatePrefixed(prefix),
                        trailingTrivia: identifier.trailingTrivia
                    ),
                    typeAnnotation: binding.typeAnnotation,
                    initializer: binding.initializer,
                    accessorBlock: binding.accessorBlock,
                    trailingComma: binding.trailingComma,
                    trailingTrivia: binding.trailingTrivia)
                
            }
        }
        
        return PatternBindingListSyntax(bindings)
    }
}

extension VariableDeclSyntax {
    func privatePrefixed(_ prefix: String, addingAttribute attribute: AttributeSyntax) -> VariableDeclSyntax {
        let newAttributes = attributes + [.attribute(attribute)]
        return VariableDeclSyntax(
            leadingTrivia: leadingTrivia,
            attributes: newAttributes,
            modifiers: modifiers.privatePrefixed(prefix),
            bindingSpecifier: TokenSyntax(bindingSpecifier.tokenKind, leadingTrivia: .space, trailingTrivia: .space, presence: .present),
            bindings: bindings.privatePrefixed(prefix),
            trailingTrivia: trailingTrivia
        )
    }
    
    var isValidForObservation: Bool {
        !isComputed && isInstance && !isImmutable && identifier != nil
    }
}

extension StorageMacro: MemberMacro {
    public static func expansion<
        Declaration: DeclGroupSyntax,
        Context: MacroExpansionContext
    >(
        of node: AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] {
        guard let identified = declaration.asProtocol(NamedDeclSyntax.self) else {
            return []
        }
        
        guard let property = declaration.as(ClassDeclSyntax.self) else {
            return []
        }
        
        let storageType = identified.name.trimmed
        
        if declaration.isEnum {
            // enumerations cannot store properties
            throw DiagnosticsError(syntax: node, message: "'@Storage' cannot be applied to enumeration type '\(storageType.text)'", id: .invalidApplication)
        }
        if declaration.isStruct {
            // structs are not yet supported; copying/mutation semantics tbd
            throw DiagnosticsError(syntax: node, message: "'@Storage' cannot be applied to struct type '\(storageType.text)'", id: .invalidApplication)
        }
        if declaration.isActor {
            // actors cannot yet be supported for their isolation
            throw DiagnosticsError(syntax: node, message: "'@Storage' cannot be applied to actor type '\(storageType.text)'", id: .invalidApplication)
        }
        
        var declarations = [DeclSyntax]()
        
        declaration.addIfNeeded(StorageMacro.registrarVariable(storageType), to: &declarations)
        declaration.addIfNeeded(StorageMacro.accessFunction(storageType), to: &declarations)
        declaration.addIfNeeded(StorageMacro.withMutationFunction(storageType), to: &declarations)
        declaration.addIfNeeded(StorageMacro.classNameVariable(property.name.text), to: &declarations)
        
        return declarations
    }
}

extension StorageMacro: MemberAttributeMacro {
    public static func expansion<
        Declaration: DeclGroupSyntax,
        MemberDeclaration: DeclSyntaxProtocol,
        Context: MacroExpansionContext
    >(
        of node: AttributeSyntax,
        attachedTo declaration: Declaration,
        providingAttributesFor member: MemberDeclaration,
        in context: Context
    ) throws -> [AttributeSyntax] {
        guard let property = member.as(VariableDeclSyntax.self),
              property.isValidForObservation,
              property.identifier != nil
        else {
            return []
        }
        
        // dont apply to ignored properties or properties that are already flagged as tracked
        if property.hasMacroApplication(StorageMacro.transientMacroName) ||
            property.hasMacroApplication(StorageMacro.observationIgnoredMacroName) ||
            property.hasMacroApplication(StorageMacro.localStoragePropertyMacroName) ||
            property.hasMacroApplication(StorageMacro.observationTrackedMacroName) {
            return []
        }
        
        
        return [
            AttributeSyntax(attributeName: IdentifierTypeSyntax(name: .identifier(StorageMacro.localStoragePropertyMacroName)))
        ]
    }
}

extension StorageMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // This method can be called twice - first with an empty `protocols` when
        // no conformance is needed, and second with a `MissingTypeSyntax` instance.
        if protocols.isEmpty {
            return []
        }
        
        let decl: DeclSyntax = """
                extension \(raw: type.trimmedDescription): \(raw: observationQualifiedConformanceName) {}
                """
        
        let ext = decl.cast(ExtensionDeclSyntax.self)
        
        if let availability = declaration.attributes.availability {
            return [ext.with(\.attributes, availability)]
        } else {
            return [ext]
        }
    }
}
