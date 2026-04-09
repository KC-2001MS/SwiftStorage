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
    
    
    static let storedPropertyMacroName = "_StoredProperty"
    
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

    static func shouldNotifyObserversFunction() -> DeclSyntax {
        return
      """
      private nonisolated func shouldNotifyObservers<Member>(_ lhs: Member, _ rhs: Member) -> Bool { true }
      """
    }

    static func shouldNotifyObserversEquatableFunction() -> DeclSyntax {
        return
      """
      private nonisolated func shouldNotifyObservers<Member: Equatable>(_ lhs: Member, _ rhs: Member) -> Bool { lhs != rhs }
      """
    }

    static func shouldNotifyObserversAnyObjectFunction() -> DeclSyntax {
        return
      """
      private nonisolated func shouldNotifyObservers<Member: AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool { lhs !== rhs }
      """
    }

    static func shouldNotifyObserversEquatableAnyObjectFunction() -> DeclSyntax {
        return
      """
      private nonisolated func shouldNotifyObservers<Member: Equatable & AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool { lhs != rhs }
      """
    }
    
//    static func loadFunction<Declaration: DeclGroupSyntax>(declaration: Declaration) -> DeclSyntax {
//        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
//            return ""
//        }
//        
//        let properties = classDecl.memberBlock.members.compactMap { member -> (
//            String,
//            String
//        )? in
//            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
//                  let identifier = varDecl.bindings.first?.pattern.as(
//                    IdentifierPatternSyntax.self
//                  )?.identifier.text,
//                  let typeAnnotation = varDecl.bindings.first?.typeAnnotation?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) else {
//                return nil
//            }
//            return (identifier, typeAnnotation)
//        }
//        
//        return
//                """
//                func load() {
//                    let keyValueStore = NSUbiquitousKeyValueStore.default
//                \(raw: properties.map { (name, type) in
//                    """
//                    self.\(name) = keyValueStore.object(forKey: "\(name)") as? \(type) ?? self.\(name)
//                    """
//                }.joined(separator: "\n"))
//                }
//                """
//    }
    
    static var ignoredAttribute: AttributeSyntax {
        AttributeSyntax(
            leadingTrivia: .space,
            atSign: .atSignToken(),
            attributeName: IdentifierTypeSyntax(
                name: .identifier(transientMacroName)
            ),
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
    
    init(
        message: String,
        diagnosticID: SwiftDiagnostics.MessageID,
        severity: SwiftDiagnostics.DiagnosticSeverity = .error
    ) {
        self.message = message
        self.diagnosticID = diagnosticID
        self.severity = severity
    }
    
    init(
        message: String,
        domain: String,
        id: ID,
        severity: SwiftDiagnostics.DiagnosticSeverity = .error
    ) {
        self.message = message
        self.diagnosticID = MessageID(domain: domain, id: id.rawValue)
        self.severity = severity
    }
}

extension DiagnosticsError {
    init<S: SyntaxProtocol>(
        syntax: S,
        message: String,
        domain: String = "Strage",
        id: ObservationDiagnostic.ID,
        severity: SwiftDiagnostics.DiagnosticSeverity = .error
    ) {
        self.init(
            diagnostics: [
                Diagnostic(
                    node: Syntax(syntax),
                    message: ObservationDiagnostic(
                        message: message,
                        domain: domain,
                        id: id,
                        severity: severity
                    )
                )
            ]
        )
    }
}

extension DeclModifierListSyntax {
    func privatePrefixed(_ prefix: String) -> DeclModifierListSyntax {
        let modifier: DeclModifierSyntax = DeclModifierSyntax(
            name: "private",
            trailingTrivia: .space
        )
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
            return TokenSyntax(
                .identifier(prefix + identifier),
                leadingTrivia: leadingTrivia,
                trailingTrivia: trailingTrivia,
                presence: presence
            )
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
            if let identifier = binding.pattern.as(
                IdentifierPatternSyntax.self
            ) {
                bindings[index] = PatternBindingSyntax(
                    leadingTrivia: binding.leadingTrivia,
                    pattern: IdentifierPatternSyntax(
                        leadingTrivia: identifier.leadingTrivia,
                        identifier: identifier.identifier
                            .privatePrefixed(prefix),
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
            bindingSpecifier: TokenSyntax(
                bindingSpecifier.tokenKind,
                leadingTrivia: .space,
                trailingTrivia: .space,
                presence: .present
            ),
            bindings: bindings.privatePrefixed(prefix),
            trailingTrivia: trailingTrivia
        )
    }

    func privatePrefixed(_ prefix: String, addingAttribute attribute: AttributeSyntax, removingAttribute name: String) -> VariableDeclSyntax {
        let filteredAttributes = attributes.filter { attr in
            switch attr {
            case .attribute(let a):
                return a.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }) != [.identifier(name)]
            default:
                return true
            }
        }
        let newAttributes = filteredAttributes + [.attribute(attribute)]
        return VariableDeclSyntax(
            leadingTrivia: leadingTrivia,
            attributes: newAttributes,
            modifiers: modifiers.privatePrefixed(prefix),
            bindingSpecifier: TokenSyntax(
                bindingSpecifier.tokenKind,
                leadingTrivia: .space,
                trailingTrivia: .space,
                presence: .present
            ),
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
            throw DiagnosticsError(
                syntax: node,
                message: "'@Storage' cannot be applied to enumeration type '\(storageType.text)'",
                id: .invalidApplication
            )
        }
        if declaration.isStruct {
            // structs are not yet supported; copying/mutation semantics tbd
            throw DiagnosticsError(
                syntax: node,
                message: "'@Storage' cannot be applied to struct type '\(storageType.text)'",
                id: .invalidApplication
            )
        }
        if declaration.isActor {
            // actors cannot yet be supported for their isolation
            throw DiagnosticsError(
                syntax: node,
                message: "'@Storage' cannot be applied to actor type '\(storageType.text)'",
                id: .invalidApplication
            )
        }
        
        var declarations = [DeclSyntax]()

        declaration
            .addIfNeeded(
                StorageMacro.registrarVariable(storageType),
                to: &declarations
            )
        declaration
            .addIfNeeded(
                StorageMacro.accessFunction(storageType),
                to: &declarations
            )
        declaration
            .addIfNeeded(
                StorageMacro.withMutationFunction(storageType),
                to: &declarations
            )
        declaration
            .addIfNeeded(
                StorageMacro.classNameVariable(property.name.text),
                to: &declarations
            )
        declaration
            .addIfNeeded(
                StorageMacro.shouldNotifyObserversFunction(),
                to: &declarations
            )
        declaration
            .addIfNeeded(
                StorageMacro.shouldNotifyObserversEquatableFunction(),
                to: &declarations
            )
        declaration
            .addIfNeeded(
                StorageMacro.shouldNotifyObserversAnyObjectFunction(),
                to: &declarations
            )
        declaration
            .addIfNeeded(
                StorageMacro.shouldNotifyObserversEquatableAnyObjectFunction(),
                to: &declarations
            )

        // Parse class default storage type expression from @Storage(type:) arguments
        var classDefaultTypeExpr: String = ".local"
        switch node.arguments {
        case .argumentList(let args):
            for arg in args {
                if let label = arg.label?.text, label == "type" {
                    classDefaultTypeExpr = arg.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        default:
            break
        }

        // Collect cloud properties for sync code generation
        let className = property.name.text
        var cloudProperties: [(identifier: String, keyExpression: String)] = []

        for member in declaration.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  varDecl.isValidForObservation,
                  let identifier = varDecl.identifier?.text else {
                continue
            }

            // Skip non-persisted properties
            if varDecl.hasMacroApplication(StorageMacro.transientMacroName) ||
               varDecl.hasMacroApplication(StorageMacro.observationIgnoredMacroName) ||
               varDecl.hasMacroApplication(StorageMacro.observationTrackedMacroName) ||
               varDecl.hasAttributeOption("ephemeral") {
                continue
            }

            // Determine effective storage type
            var effectiveType = classDefaultTypeExpr
            if varDecl.hasMacroApplication(StorageMacro.attributeMacroName),
               let typeText = varDecl.attributeTypeValue(for: "type") {
                effectiveType = typeText
            }

            guard effectiveType == ".cloud" else { continue }

            // Determine key
            var key = "\(className).\(identifier)"
            if varDecl.hasMacroApplication(StorageMacro.attributeMacroName),
               let customKey = varDecl.attributeStringValue(for: "key") {
                key = customKey
            }

            // Determine hashing
            var hashed = true
            if varDecl.hasMacroApplication(StorageMacro.attributeMacroName),
               let hashedValue = varDecl.attributeBoolValue(for: "hashed") {
                hashed = hashedValue
            }

            let keyExpression: String
            if hashed {
                keyExpression = "#hashify(\"\(key)\")"
            } else {
                keyExpression = "\"\(key)\""
            }

            cloudProperties.append((identifier: identifier, keyExpression: keyExpression))
        }

        // Generate cloud sync code if any cloud properties exist
        if !cloudProperties.isEmpty {
            let cases = cloudProperties.map { prop in
                """
                case \(prop.keyExpression):
                \(registrarVariableName).willSet(self, keyPath: \\.\(prop.identifier))
                \(registrarVariableName).didSet(self, keyPath: \\.\(prop.identifier))
                """
            }.joined(separator: "\n")

            let cloudKeysDecl: DeclSyntax =
            """
            private func _$cloudKeys(_ key: String) -> Bool {
            switch key {
            \(raw: cases)
            default:
            return false
            }
            return true
            }
            """

            let observerDecl: DeclSyntax =
            """
            @\(raw: transientMacroName) private var _$cloudNotificationObserver: (any NSObjectProtocol)? = nil
            """

            let syncFuncDecl: DeclSyntax =
            """
            private func _$startCloudSync() {
            guard _$cloudNotificationObserver == nil else { return }
            NSUbiquitousKeyValueStore.default.synchronize()
            _$cloudNotificationObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
            ) { @Sendable [weak self] notification in
            guard let self,
            let userInfo = notification.userInfo,
            let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }
            for key in changedKeys {
            _ = self._$cloudKeys(key)
            }
            }
            }
            """

            declarations.append(cloudKeysDecl)
            declarations.append(observerDecl)
            declarations.append(syncFuncDecl)
        }

        // Generate unified _$store variable for class default backend
        // Wrap in parentheses to handle complex expressions (ternary, function calls, etc.)
        // and qualify member access expressions (e.g. ".local" → "StorageType.local") since the
        // explicit type annotation `any StorageBackend` prevents implicit resolution.
        let qualifiedClassTypeExpr = classDefaultTypeExpr.hasPrefix(".") ? "StorageType\(classDefaultTypeExpr)" : classDefaultTypeExpr
        let classStoreDecl: DeclSyntax =
        """
        @\(raw: transientMacroName) private let _$store: any StorageBackend = (\(raw: qualifiedClassTypeExpr)).backend
        """
        declarations.append(classStoreDecl)

        // Generate per-property _$store_<name> for @Attribute(type:) overrides
        for member in declaration.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  varDecl.isValidForObservation,
                  let identifier = varDecl.identifier?.text else {
                continue
            }
            if varDecl.hasMacroApplication(StorageMacro.transientMacroName) ||
               varDecl.hasMacroApplication(StorageMacro.observationIgnoredMacroName) ||
               varDecl.hasMacroApplication(StorageMacro.observationTrackedMacroName) ||
               varDecl.hasAttributeOption("ephemeral") {
                continue
            }
            if varDecl.hasMacroApplication(StorageMacro.attributeMacroName),
               let typeText = varDecl.attributeTypeValue(for: "type") {
                let qualifiedTypeText = typeText.hasPrefix(".") ? "StorageType\(typeText)" : typeText
                let propStoreDecl: DeclSyntax =
                """
                @\(raw: transientMacroName) private let _$store_\(raw: identifier): any StorageBackend = (\(raw: qualifiedTypeText)).backend
                """
                declarations.append(propStoreDecl)
            }
        }

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
            property
            .hasMacroApplication(StorageMacro.observationIgnoredMacroName) ||
            property
            .hasMacroApplication(StorageMacro.storedPropertyMacroName) ||
            property
            .hasMacroApplication(StorageMacro.observationTrackedMacroName) {
            return []
        }

        // @Attribute(.ephemeral) → apply @ObservationTracked instead of @_StoredProperty
        if property.hasAttributeOption("ephemeral") {
            let trackedAttribute: AttributeSyntax =
            """
            @\(IdentifierTypeSyntax(name: .identifier(StorageMacro.observationTrackedMacroName)))
            """
            return [trackedAttribute]
        }

        var typeValue: String = ".local"

        switch node.arguments {
        case .argumentList(let args):
            for arg in args {
                if let label = arg.label?.text, label == "type" {
                    typeValue = arg.expression.description.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                }
            }
        default:
            break
        }

        let attribute: AttributeSyntax =
        """
        @\(IdentifierTypeSyntax(name: .identifier(StorageMacro.storedPropertyMacroName)))(type: \(raw: typeValue))
        """

        return [
            attribute
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
