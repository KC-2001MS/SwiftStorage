//
//  StorageMigrationPlan.swift
//  SwiftStorage
//
//  Created by SwiftStorage contributors.
//


#if canImport(Foundation)
/// A protocol that describes the complete evolution of a storage schema and how
/// to migrate persisted data between versions.
///
/// `StorageMigrationPlan` is the SwiftStorage equivalent of SwiftData's
/// `SchemaMigrationPlan`. Conform a type to this protocol to declare:
///
/// 1. The ordered list of all schema versions your app has ever shipped (``schemas``).
/// 2. The ``StorageMigrationStage`` instances that connect consecutive versions (``stages``).
///
/// ## Overview
///
/// When you pass a conforming type to ``StorageMigrator/migrate(for:on:assumeVersionIfMissing:)-80wcp``,
/// the migrator reads the currently stored schema version from the backend, locates
/// the applicable stages, and executes them in order — bringing the persisted data
/// up to the latest version.
///
/// ## Defining a Migration Plan
///
/// ```swift
/// enum SettingsSchemaV1: VersionedStorageSchema {
///     static let versionIdentifier = StorageSchemaVersion(1, 0, 0)
/// }
///
/// enum SettingsSchemaV2: VersionedStorageSchema {
///     static let versionIdentifier = StorageSchemaVersion(2, 0, 0)
/// }
///
/// enum SettingsSchemaV3: VersionedStorageSchema {
///     static let versionIdentifier = StorageSchemaVersion(3, 0, 0)
/// }
///
/// enum SettingsMigrationPlan: StorageMigrationPlan {
///     static var schemas: [any VersionedStorageSchema.Type] {
///         [SettingsSchemaV1.self, SettingsSchemaV2.self, SettingsSchemaV3.self]
///     }
///
///     static var stages: [StorageMigrationStage] {
///         [
///             // V1 → V2: add "fontSize" (backward-compatible, no data transform needed)
///             .lightweight(
///                 fromVersion: SettingsSchemaV1.self,
///                 toVersion: SettingsSchemaV2.self
///             ),
///             // V2 → V3: rename "userName" to "displayName"
///             .custom(
///                 fromVersion: SettingsSchemaV2.self,
///                 toVersion: SettingsSchemaV3.self,
///                 willMigrate: { context in
///                     context.renameKey(
///                         from: "Settings.userName",
///                         to: "Settings.displayName"
///                     )
///                 },
///                 didMigrate: nil
///             )
///         ]
///     }
/// }
/// ```
///
/// ## Triggering Migration
///
/// Call ``StorageMigrator/migrate(for:on:assumeVersionIfMissing:)-80wcp`` at app
/// startup — before any `@Storage` class is accessed — to ensure persisted data
/// is up to date:
///
/// ```swift
/// @main
/// struct MyApp: App {
///     init() {
///         try! StorageMigrator.migrate(for: SettingsMigrationPlan.self)
///     }
///     var body: some Scene { WindowGroup { ContentView() } }
/// }
/// ```
///
/// ## Topics
///
/// ### Declaring the Schema History
///
/// - ``schemas``
/// - ``stages``
public protocol StorageMigrationPlan {
    /// An ordered list of all versioned schemas, from oldest to newest.
    ///
    /// The **last** element is treated as the current (latest) schema version.
    /// The migrator uses this array to determine the target version and to
    /// validate that all stages cover the full upgrade path.
    static var schemas: [any VersionedStorageSchema.Type] { get }

    /// The migration stages that connect consecutive schema versions.
    ///
    /// Each stage specifies a `fromVersion` and `toVersion` and must correspond
    /// to adjacent entries in ``schemas``. Stages are executed in ascending
    /// ``StorageMigrationStage/fromVersion`` order.
    static var stages: [StorageMigrationStage] { get }
}
#endif
