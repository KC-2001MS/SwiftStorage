//
//  SwiftStorage.swift
//
//
//  Created by Keisuke Chinone on 2024/07/06.
//


// The Swift Programming Language
// https://docs.swift.org/swift-book
#if canImport(Observation) && canImport(Foundation)
import Observation
import Foundation

/// Macros to adapt persistence and observation to properties in a class
///
/// Add this macro to the class as follows
/// ```swift
/// @Storage
/// final class SomeClass {
///     var someValue: Bool
///
///     init() {
///         self.someValue = false
///     }
/// }
/// ```
/// When expanded, it looks like this
/// ```swift
/// final class SomeClass {
///     @LocalStorageProperty
///     var someValue: Bool
///
///     init() {
///         self.someValue = false
///     }
///
///     @Transient private let _$observationRegistrar = Observation.ObservationRegistrar()
///
///     internal nonisolated func access<Member>(
///         keyPath: KeyPath<SomeClass, Member>
///     ) {
///         _$observationRegistrar.access(self, keyPath: keyPath)
///     }
///
///     internal nonisolated func withMutation<Member, MutationResult>(
///         keyPath: KeyPath<SomeClass, Member>,
///         _ mutation: () throws -> MutationResult
///     ) rethrows -> MutationResult {
///         try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
///     }
///
///     @Transient private let className = "SomeClass"
/// }
/// ```
/// Use the ``Transient`` macro if there are properties you do not want to preserve. You can also use the [ObservationTracked](https://developer.apple.com/documentation/observation/observationignored()) macro instead.
@attached(member, names: named(_$id), named(_$observationRegistrar), named(access), named(withMutation), named(className), named(store))
@attached(memberAttribute)
@attached(extension, conformances: Observable)
public macro Storage() = #externalMacro(module: "SwiftStorageMacros", type: "StorageMacro")

/// Macro for specifying the property whose value is to be persisted
///
/// This property is automatically added by the Storege macro. It is not necessary to describe it.
@attached(accessor, names: named(init), named(get), named(set), named(_modify))
@attached(peer, names: prefixed(_))
public macro LocalStorageProperty() = #externalMacro(module: "SwiftStorageMacros", type: "LocalStoragePropertyMacro")
/// Macro to set a key to associate the value
/// - Parameters:
///  - key: A keys to associate values
///
/// Add keys to associate values as follows
/// ```swift
/// @Storage
/// final class SomeClass {
///     @Attribute(key: "SomeValue")
///     var someValue: Bool
///
///     init() {
///         self.someValue = false
///     }
/// }
/// ```
@attached(peer)
public macro Attribute(key: String) = #externalMacro(module: "SwiftStorageMacros", type: "AttributeMacro")

/// Macro for specifying properties that are not observed and persisted
///
/// Add the following to the properties that you want to make non-persistent
/// ```swift
/// @Storage
/// final class SomeClass {
///     @Transient
///     var someValue: Bool
///
///     init() {
///         self.someValue = false
///     }
/// }
/// ```
@attached(accessor, names: named(willSet))
public macro Transient() = #externalMacro(module: "SwiftStorageMacros", type: "TransientMacro")
#endif
