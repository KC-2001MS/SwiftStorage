//
//  StorageMigrationStage.swift
//  SwiftStorage
//
//  Created by SwiftStorage contributors.
//


#if canImport(Foundation)
/// Describes how to migrate persisted data between two versions of a storage schema.
///
/// `StorageMigrationStage` is the SwiftStorage equivalent of SwiftData's `MigrationStage`.
/// Each stage connects exactly two ``VersionedStorageSchema`` versions and declares
/// what — if any — data transformations are required.
///
/// ## Overview
///
/// SwiftStorage provides two kinds of migration stages:
///
/// - **Lightweight** (``lightweight(fromVersion:toVersion:)``): No data transformation
///   is performed. The stored schema version is simply advanced. Use this when the
///   schema change is backward-compatible — for example, when you add a new
///   property whose absence is already handled by its default value.
///
/// - **Custom** (``custom(fromVersion:toVersion:willMigrate:didMigrate:)``): You supply
///   one or two closures that receive a ``StorageMigrationContext``. Use this when
///   keys need to be renamed, values need to be transformed, or obsolete keys need
///   to be removed.
///
/// ## Choosing Between Lightweight and Custom
///
/// | Schema Change | Stage Type |
/// |---|---|
/// | Add a new property with a default | ``lightweight(fromVersion:toVersion:)`` |
/// | Remove a property (old key can remain) | ``lightweight(fromVersion:toVersion:)`` |
/// | Rename a property / change a key | ``custom(fromVersion:toVersion:willMigrate:didMigrate:)`` |
/// | Change a value's type | ``custom(fromVersion:toVersion:willMigrate:didMigrate:)`` |
/// | Split or merge properties | ``custom(fromVersion:toVersion:willMigrate:didMigrate:)`` |
///
/// ## Example
///
/// ```swift
/// // Lightweight: just adding a new "fontSize" property (default is handled by @Storage).
/// let v1toV2 = StorageMigrationStage.lightweight(
///     fromVersion: SchemaV1.self,
///     toVersion: SchemaV2.self
/// )
///
/// // Custom: rename "userName" to "displayName".
/// let v2toV3 = StorageMigrationStage.custom(
///     fromVersion: SchemaV2.self,
///     toVersion: SchemaV3.self,
///     willMigrate: { context in
///         context.renameKey(from: "Settings.userName", to: "Settings.displayName")
///     },
///     didMigrate: nil
/// )
/// ```
///
/// ## Topics
///
/// ### Defining Stages
///
/// - ``lightweight(fromVersion:toVersion:)``
/// - ``custom(fromVersion:toVersion:willMigrate:didMigrate:)``
///
/// ### Inspecting Stages
///
/// - ``fromVersion``
/// - ``toVersion``
public enum StorageMigrationStage: Sendable {
    /// A lightweight migration that requires no data transformation.
    ///
    /// When this stage is executed, no closures are called. The migrator simply
    /// advances through the stage and, once all stages complete, stamps the
    /// latest schema version.
    ///
    /// Use this for backward-compatible changes such as adding a new persisted
    /// property that has a sensible default value.
    ///
    /// - Parameters:
    ///   - fromVersion: The schema version before this migration.
    ///   - toVersion: The schema version after this migration.
    case lightweight(
        fromVersion: any VersionedStorageSchema.Type,
        toVersion: any VersionedStorageSchema.Type
    )

    /// A custom migration that executes user-provided closures to transform data.
    ///
    /// Both `willMigrate` and `didMigrate` are optional. They are called in order:
    /// `willMigrate` first, then `didMigrate`. Each closure receives a
    /// ``StorageMigrationContext`` that provides read, write, rename, and delete
    /// operations on the underlying storage backend.
    ///
    /// If either closure throws, the migration is aborted and the schema version
    /// is **not** updated, so the migration will be retried on the next app launch.
    ///
    /// - Parameters:
    ///   - fromVersion: The schema version before this migration.
    ///   - toVersion: The schema version after this migration.
    ///   - willMigrate: A closure executed before advancing the version.
    ///     Use this for the primary data transformation logic.
    ///   - didMigrate: A closure executed after `willMigrate` completes.
    ///     Use this for post-migration cleanup or validation.
    case custom(
        fromVersion: any VersionedStorageSchema.Type,
        toVersion: any VersionedStorageSchema.Type,
        willMigrate: (@Sendable (StorageMigrationContext) throws -> Void)?,
        didMigrate: (@Sendable (StorageMigrationContext) throws -> Void)?
    )

    /// The schema version that this stage migrates **from**.
    ///
    /// The migrator uses this value to determine whether the stage is applicable
    /// given the currently stored schema version.
    public var fromVersion: any VersionedStorageSchema.Type {
        switch self {
        case .lightweight(let from, _): return from
        case .custom(let from, _, _, _): return from
        }
    }

    /// The schema version that this stage migrates **to**.
    ///
    /// After all applicable stages have executed successfully, the migrator
    /// stamps the ``toVersion`` of the last executed stage's target (or the
    /// latest schema version in the plan) into the storage backend.
    public var toVersion: any VersionedStorageSchema.Type {
        switch self {
        case .lightweight(_, let to): return to
        case .custom(_, let to, _, _): return to
        }
    }
}
#endif
