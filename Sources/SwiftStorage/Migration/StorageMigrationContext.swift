//
//  StorageMigrationContext.swift
//  SwiftStorage
//
//  Created by SwiftStorage contributors.
//


#if canImport(Foundation)
/// An object that provides key-value operations during a custom storage migration.
///
/// `StorageMigrationContext` is the SwiftStorage equivalent of the `ModelContext`
/// parameter passed to SwiftData's `MigrationStage.custom(willMigrate:didMigrate:)`
/// closures. While `ModelContext` provides model-level CRUD operations,
/// `StorageMigrationContext` exposes the raw key-value primitives needed to
/// transform persisted data in `UserDefaults` or `NSUbiquitousKeyValueStore`.
///
/// ## Overview
///
/// You receive a `StorageMigrationContext` as the sole argument in the
/// `willMigrate` and `didMigrate` closures of a
/// ``StorageMigrationStage/custom(fromVersion:toVersion:willMigrate:didMigrate:)``
/// stage. Use it to:
///
/// - **Read** existing values with ``value(forKey:default:)-1hbia`` or ``value(forKey:default:)-50omu``.
/// - **Write** new or transformed values with ``setValue(_:forKey:)-4daxr`` or ``setValue(_:forKey:)-1loig``.
/// - **Rename** keys with ``renameKey(from:to:)``, which atomically copies and removes.
/// - **Delete** obsolete keys with ``removeValue(forKey:)``.
/// - **Check** for key existence with ``hasValue(forKey:)``.
///
/// ## Example
///
/// ```swift
/// .custom(
///     fromVersion: SchemaV1.self,
///     toVersion: SchemaV2.self,
///     willMigrate: { context in
///         // Rename a key
///         context.renameKey(from: "Settings.userName", to: "Settings.displayName")
///
///         // Transform a value
///         let darkMode: Bool = context.value(forKey: "Settings.darkMode", default: false)
///         context.setValue(darkMode ? "dark" : "light", forKey: "Settings.theme")
///         context.removeValue(forKey: "Settings.darkMode")
///     },
///     didMigrate: nil
/// )
/// ```
///
/// > Important: The context is **not** designed for concurrent access. Migration
/// > closures run synchronously on the calling thread.
///
/// ## Topics
///
/// ### Reading Values
///
/// - ``value(forKey:default:)-1hbia``
/// - ``value(forKey:default:)-50omu``
///
/// ### Writing Values
///
/// - ``setValue(_:forKey:)-4daxr``
/// - ``setValue(_:forKey:)-1loig``
///
/// ### Managing Keys
///
/// - ``renameKey(from:to:)``
/// - ``removeValue(forKey:)``
/// - ``hasValue(forKey:)``
public final class StorageMigrationContext: @unchecked Sendable {
    private let backend: any StorageBackend

    init(backend: any StorageBackend) {
        self.backend = backend
    }

    // MARK: - Read operations

    /// Reads a `Storable` value from the storage backend.
    ///
    /// Use this overload for primitive types that conform to ``Storable``,
    /// such as `String`, `Int`, `Double`, `Bool`, `Data`, and `Date`.
    ///
    /// - Parameters:
    ///   - key: The storage key to look up.
    ///   - defaultValue: The value to return if the key does not exist.
    /// - Returns: The persisted value, or `defaultValue` if the key is absent.
    public func value<T: Storable>(forKey key: String, default defaultValue: T) -> T {
        backend.persistedValue(forKey: key, default: defaultValue)
    }

    /// Reads a `Codable` value from the storage backend.
    ///
    /// Use this overload for complex types that conform to `Codable`. The value
    /// is deserialized from JSON data stored in the backend.
    ///
    /// - Parameters:
    ///   - key: The storage key to look up.
    ///   - defaultValue: The value to return if the key does not exist or decoding fails.
    /// - Returns: The decoded value, or `defaultValue` if the key is absent or decoding fails.
    public func value<T: Codable>(forKey key: String, default defaultValue: T) -> T {
        backend.persistedValue(forKey: key, default: defaultValue)
    }

    // MARK: - Write operations

    /// Writes a `Storable` value to the storage backend.
    ///
    /// Use this overload for primitive types that conform to ``Storable``.
    ///
    /// - Parameters:
    ///   - value: The value to persist.
    ///   - key: The storage key under which to store the value.
    public func setValue<T: Storable>(_ value: T, forKey key: String) {
        backend.setPersisted(value, forKey: key)
    }

    /// Writes a `Codable` value to the storage backend.
    ///
    /// Use this overload for complex types that conform to `Codable`. The value
    /// is serialized to JSON data before being stored.
    ///
    /// - Parameters:
    ///   - value: The value to persist.
    ///   - key: The storage key under which to store the value.
    public func setValue<T: Codable>(_ value: T, forKey key: String) {
        backend.setPersisted(value, forKey: key)
    }

    // MARK: - Key management

    /// Renames a storage key by copying its raw value to a new key and removing the old one.
    ///
    /// This operation is performed at the raw storage level, so the value does not
    /// need to be deserialized. If the source key does not exist, no action is taken
    /// for the copy, and the removal is a no-op.
    ///
    /// - Parameters:
    ///   - oldKey: The existing key to rename.
    ///   - newKey: The new key name.
    public func renameKey(from oldKey: String, to newKey: String) {
        backend.copyRawValue(fromKey: oldKey, toKey: newKey)
        backend.removeValue(forKey: oldKey)
    }

    /// Removes a key and its associated value from the storage backend.
    ///
    /// Use this to clean up keys that are no longer part of the schema after migration.
    /// If the key does not exist, this method is a no-op.
    ///
    /// - Parameter key: The storage key to remove.
    public func removeValue(forKey key: String) {
        backend.removeValue(forKey: key)
    }

    /// Returns a Boolean value indicating whether a value exists for the specified key.
    ///
    /// Use this to conditionally perform migration logic only when data from a
    /// previous schema version is present.
    ///
    /// - Parameter key: The storage key to check.
    /// - Returns: `true` if the backend contains a value for `key`; otherwise, `false`.
    public func hasValue(forKey key: String) -> Bool {
        backend.hasValue(forKey: key)
    }
}
#endif
