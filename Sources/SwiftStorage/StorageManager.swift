//
//  StorageManager.swift
//  SwiftStorage
//
//  Created by 茅根啓介 on 2024/12/11.
//

import Foundation

/// A Sendable wrapper holding a weak reference, used by macro-generated cloud sync code.
public final class _$WeakSendableRef<T: AnyObject>: @unchecked Sendable {
    public weak var value: T?
    public init(_ value: T) { self.value = value }
}

/// A protocol that abstracts key-value persistence backends.
///
/// `StorageBackend` provides a unified interface for reading and writing
/// persisted values across different storage mechanisms. SwiftStorage ships
/// with conformances for `UserDefaults` (local storage) and
/// `NSUbiquitousKeyValueStore` (iCloud key-value storage).
///
/// The `@Storage` macro generates code that calls these methods through the
/// backend instance resolved from ``StorageType/backend``.
///
/// ## Conforming to StorageBackend
///
/// To use a custom storage backend, conform your type to this protocol and
/// implement all required methods. For example, you could create an in-memory
/// backend for testing:
///
/// ```swift
/// final class InMemoryBackend: StorageBackend {
///     var store: [String: Any] = [:]
///
///     func persistedValue<T: Storable>(forKey key: String, default defaultValue: T) -> T {
///         store[key] as? T ?? defaultValue
///     }
///     // ... implement remaining methods
/// }
/// ```
///
/// ## Topics
///
/// ### Reading Values
///
/// - ``persistedValue(forKey:default:)-99wov``
/// - ``persistedValue(forKey:default:)-4jwbl``
///
/// ### Writing Values
///
/// - ``setPersisted(_:forKey:)-7jiss``
/// - ``setPersisted(_:forKey:)-1ft2v``
///
/// ### Key Management
///
/// - ``removeValue(forKey:)``
/// - ``hasValue(forKey:)``
/// - ``copyRawValue(fromKey:toKey:)``
public protocol StorageBackend: AnyObject {
    /// Reads a `Storable` value from the backend, returning a default if absent.
    ///
    /// - Parameters:
    ///   - key: The key to look up.
    ///   - defaultValue: The value to return when no persisted value exists.
    /// - Returns: The persisted value, or `defaultValue` if the key is absent.
    func persistedValue<T: Storable>(forKey key: String, default defaultValue: T) -> T

    /// Reads a `Codable` value from the backend, returning a default if absent.
    ///
    /// The value is expected to be stored as JSON-encoded `Data`.
    ///
    /// - Parameters:
    ///   - key: The key to look up.
    ///   - defaultValue: The value to return when no persisted value exists or decoding fails.
    /// - Returns: The decoded value, or `defaultValue` if the key is absent or decoding fails.
    func persistedValue<T: Codable>(forKey key: String, default defaultValue: T) -> T

    /// Writes a `Storable` value to the backend.
    ///
    /// - Parameters:
    ///   - value: The value to persist.
    ///   - key: The key under which to store the value.
    func setPersisted<T: Storable>(_ value: T, forKey key: String)

    /// Writes a `Codable` value to the backend.
    ///
    /// The value is JSON-encoded to `Data` before being stored.
    ///
    /// - Parameters:
    ///   - value: The value to persist.
    ///   - key: The key under which to store the value.
    func setPersisted<T: Codable>(_ value: T, forKey key: String)

    /// Removes the value associated with the specified key.
    ///
    /// If the key does not exist in the backend, this method is a no-op.
    /// This method is used by ``StorageMigrationContext/removeValue(forKey:)``
    /// and ``StorageMigrationContext/renameKey(from:to:)`` during schema migrations.
    ///
    /// - Parameter key: The key whose value should be removed.
    func removeValue(forKey key: String)

    /// Returns a Boolean value indicating whether the backend contains a value
    /// for the specified key.
    ///
    /// This method is used by ``StorageMigrationContext/hasValue(forKey:)``
    /// to conditionally perform migration logic.
    ///
    /// - Parameter key: The key to check.
    /// - Returns: `true` if a value exists for `key`; otherwise, `false`.
    func hasValue(forKey key: String) -> Bool

    /// Copies the raw value from one key to another without deserialization.
    ///
    /// This operation preserves the original storage representation, making it
    /// safe for renaming keys regardless of the value's type. If the source key
    /// does not exist, no value is written to the destination.
    ///
    /// This method is used by ``StorageMigrationContext/renameKey(from:to:)``
    /// during schema migrations.
    ///
    /// - Parameters:
    ///   - source: The key to copy from.
    ///   - destination: The key to copy to. Any existing value is overwritten.
    func copyRawValue(fromKey source: String, toKey destination: String)
}

extension UserDefaults: StorageBackend {}
extension NSUbiquitousKeyValueStore: StorageBackend {}

extension UserDefaults {
    public func persistedValue<T: Storable>(forKey key: String, default defaultValue: T) -> T {
        value(forKey: key) as? T ?? defaultValue
    }

    public func persistedValue<T: Codable>(forKey key: String, default defaultValue: T) -> T {
        guard let data = value(forKey: key) as? Data else { return defaultValue }
        return (try? JSONDecoder().decode(T.self, from: data)) ?? defaultValue
    }

    public func setPersisted<T: Storable>(_ value: T, forKey key: String) {
        set(value, forKey: key)
    }

    public func setPersisted<T: Codable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            set(data, forKey: key)
        }
    }

    public func removeValue(forKey key: String) {
        removeObject(forKey: key)
    }

    public func hasValue(forKey key: String) -> Bool {
        object(forKey: key) != nil
    }

    public func copyRawValue(fromKey source: String, toKey destination: String) {
        guard let value = object(forKey: source) else { return }
        set(value, forKey: destination)
    }
}

extension NSUbiquitousKeyValueStore {
    public func persistedValue<T: Storable>(forKey key: String, default defaultValue: T) -> T {
        object(forKey: key) as? T ?? defaultValue
    }

    public func persistedValue<T: Codable>(forKey key: String, default defaultValue: T) -> T {
        guard let data = data(forKey: key) else { return defaultValue }
        return (try? JSONDecoder().decode(T.self, from: data)) ?? defaultValue
    }

    public func setPersisted<T: Storable>(_ value: T, forKey key: String) {
        set(value, forKey: key)
    }

    public func setPersisted<T: Codable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            set(data, forKey: key)
        }
    }

    public func removeValue(forKey key: String) {
        removeObject(forKey: key)
    }

    public func hasValue(forKey key: String) -> Bool {
        object(forKey: key) != nil
    }

    public func copyRawValue(fromKey source: String, toKey destination: String) {
        guard let value = object(forKey: source) else { return }
        set(value, forKey: destination)
    }
}
