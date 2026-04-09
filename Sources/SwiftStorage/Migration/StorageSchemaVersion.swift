//
//  StorageSchemaVersion.swift
//  SwiftStorage
//
//  Created by SwiftStorage contributors.
//


#if canImport(Foundation)
/// A semantic version identifier for a storage schema, following [Semantic Versioning 2.0.0](https://semver.org).
///
/// `StorageSchemaVersion` is the SwiftStorage equivalent of SwiftData's `Schema.Version`.
/// It uniquely identifies each version of your storage schema, allowing
/// ``StorageMigrator`` to determine which ``StorageMigrationStage`` instances
/// need to run when upgrading persisted data.
///
/// ## Overview
///
/// A schema version consists of three components — major, minor, and patch —
/// that together form a version string such as `"2.1.0"`. Versions are compared
/// lexicographically by component (major first, then minor, then patch) using
/// the standard `Comparable` operators.
///
/// ## Usage
///
/// Assign a `StorageSchemaVersion` to each ``VersionedStorageSchema`` conformance
/// to mark that point in your schema's evolution:
///
/// ```swift
/// enum SettingsSchemaV1: VersionedStorageSchema {
///     static let versionIdentifier = StorageSchemaVersion(1, 0, 0)
/// }
///
/// enum SettingsSchemaV2: VersionedStorageSchema {
///     static let versionIdentifier = StorageSchemaVersion(2, 0, 0)
/// }
/// ```
///
/// ## Topics
///
/// ### Creating a Version
///
/// - ``init(_:_:_:)``
///
/// ### Version Components
///
/// - ``major``
/// - ``minor``
/// - ``patch``
public struct StorageSchemaVersion: Sendable, Hashable, Comparable, CustomStringConvertible {
    /// The major version number.
    ///
    /// Increment this when you make incompatible changes that require a custom migration,
    /// such as renaming keys, changing value types, or restructuring the schema.
    public let major: Int

    /// The minor version number.
    ///
    /// Increment this when you add new functionality in a backward-compatible manner,
    /// such as adding new persisted properties that have sensible defaults.
    public let minor: Int

    /// The patch version number.
    ///
    /// Increment this for backward-compatible fixes that do not alter the storage
    /// schema structure, such as correcting a default value.
    public let patch: Int

    /// Creates a new storage schema version with the specified components.
    ///
    /// - Parameters:
    ///   - major: The major version number. Increment for breaking schema changes.
    ///   - minor: The minor version number. Increment for backward-compatible additions.
    ///   - patch: The patch version number. Increment for backward-compatible fixes.
    public init(_ major: Int, _ minor: Int, _ patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    /// A dot-separated string representation of the version (e.g., `"1.2.3"`).
    public var description: String {
        "\(major).\(minor).\(patch)"
    }

    public static func < (lhs: StorageSchemaVersion, rhs: StorageSchemaVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}

/// A protocol that describes a specific version of a storage schema.
///
/// `VersionedStorageSchema` is the SwiftStorage equivalent of SwiftData's `VersionedSchema`.
/// Each conforming type represents a snapshot of your storage schema at a particular
/// point in time. The protocol itself carries no model or key definitions — it serves
/// purely as a version marker that ``StorageMigrationStage`` and
/// ``StorageMigrationPlan`` reference to define the migration path.
///
/// ## Overview
///
/// Create one conforming type for every schema version you need to support.
/// Arrange them chronologically in your ``StorageMigrationPlan/schemas`` array
/// so the migrator can determine the correct upgrade path.
///
/// ## Usage
///
/// ```swift
/// // Version 1: initial schema with "userName" key.
/// enum SettingsSchemaV1: VersionedStorageSchema {
///     static let versionIdentifier = StorageSchemaVersion(1, 0, 0)
/// }
///
/// // Version 2: renamed "userName" to "displayName", added "fontSize".
/// enum SettingsSchemaV2: VersionedStorageSchema {
///     static let versionIdentifier = StorageSchemaVersion(2, 0, 0)
/// }
/// ```
///
/// ## Topics
///
/// ### Identifying the Version
///
/// - ``versionIdentifier``
public protocol VersionedStorageSchema {
    /// The semantic version that uniquely identifies this schema.
    ///
    /// The migrator compares this value against the version stored in the backend
    /// to decide which migration stages to execute.
    static var versionIdentifier: StorageSchemaVersion { get }
}
#endif
