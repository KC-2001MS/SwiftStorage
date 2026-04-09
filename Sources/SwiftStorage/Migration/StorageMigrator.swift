//
//  StorageMigrator.swift
//  SwiftStorage
//
//  Created by SwiftStorage contributors.
//


#if canImport(Foundation)
/// The entry point for executing storage schema migrations.
///
/// `StorageMigrator` is the SwiftStorage equivalent of the migration logic that
/// runs inside SwiftData's `ModelContainer.init()`. Call one of the `migrate`
/// methods once at app startup — **before** any `@Storage` class is accessed —
/// to bring persisted data up to the latest schema version.
///
/// ## Overview
///
/// The migrator performs the following steps:
///
/// 1. Reads the currently stored schema version from the backend
///    (stored under the internal key `_$SwiftStorage.schemaVersion`).
/// 2. Compares it against the latest version declared in the
///    ``StorageMigrationPlan/schemas`` array.
/// 3. If the stored version is already current, returns immediately.
/// 4. Otherwise, collects all ``StorageMigrationStage`` instances whose
///    ``StorageMigrationStage/fromVersion`` is at or above the stored version,
///    sorts them by version, and executes them in order.
/// 5. After all stages complete successfully, stamps the latest version into the backend.
///
/// If any stage's closure throws an error, the version is **not** updated, so the
/// migration will be retried automatically on the next app launch.
///
/// ## First Launch Behavior
///
/// On a fresh install where no schema version has been stored, the migrator
/// skips all stages and stamps the latest version immediately. This is safe
/// because `@Storage` properties use their default values when no persisted data
/// exists.
///
/// If you are adopting the migration system in an app that already has persisted
/// data from before migration support was added, pass the `assumeVersionIfMissing`
/// parameter to tell the migrator which version the existing data corresponds to:
///
/// ```swift
/// try StorageMigrator.migrate(
///     for: SettingsMigrationPlan.self,
///     assumeVersionIfMissing: StorageSchemaVersion(1, 0, 0)
/// )
/// ```
///
/// ## Multiple Backends
///
/// If your app uses both local (`UserDefaults`) and cloud
/// (`NSUbiquitousKeyValueStore`) storage, each backend tracks its schema version
/// independently. Call `migrate` once per backend:
///
/// ```swift
/// try StorageMigrator.migrate(for: LocalMigrationPlan.self, on: .local)
/// try StorageMigrator.migrate(for: CloudMigrationPlan.self, on: .cloud)
/// ```
///
/// ## Example
///
/// ```swift
/// @main
/// struct MyApp: App {
///     init() {
///         try! StorageMigrator.migrate(for: SettingsMigrationPlan.self)
///     }
///
///     var body: some Scene {
///         WindowGroup { ContentView() }
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Running Migrations
///
/// - ``migrate(for:on:assumeVersionIfMissing:)-80wcp``
/// - ``migrate(for:on:assumeVersionIfMissing:)-492xk``
public enum StorageMigrator {
    /// The key used to store the current schema version in the backend.
    private static let versionKey = "_$SwiftStorage.schemaVersion"

    /// Performs migration for the given plan on the specified storage type.
    ///
    /// This is the primary entry point for migration. It resolves the
    /// ``StorageType`` to its underlying ``StorageBackend`` and delegates
    /// to the internal migration engine.
    ///
    /// - Parameters:
    ///   - plan: The migration plan type that declares schema versions and stages.
    ///   - storageType: The storage type whose backend should be migrated.
    ///     Defaults to ``StorageType/local``.
    ///   - assumeVersionIfMissing: When no schema version is found in the backend
    ///     and this value is non-`nil`, the migrator assumes the existing data
    ///     is at this version and executes all stages from that point forward.
    ///     When `nil` (the default), a missing version is treated as a fresh
    ///     install and the latest version is stamped without running any stages.
    ///
    /// - Throws: Rethrows any error thrown by a custom migration stage closure.
    ///   When an error is thrown, the schema version is **not** updated.
    public static func migrate(
        for plan: any StorageMigrationPlan.Type,
        on storageType: StorageType = .local,
        assumeVersionIfMissing: StorageSchemaVersion? = nil
    ) throws {
        let backend = storageType.backend
        try performMigration(plan: plan, backend: backend, assumeVersionIfMissing: assumeVersionIfMissing)
    }

    /// Performs migration for the given plan on a specific backend instance.
    ///
    /// Use this overload when you have a reference to a specific ``StorageBackend``
    /// instance, such as a custom `UserDefaults` suite:
    ///
    /// ```swift
    /// let suite = UserDefaults(suiteName: "group.com.example.app")!
    /// try StorageMigrator.migrate(
    ///     for: SharedMigrationPlan.self,
    ///     on: suite
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - plan: The migration plan type that declares schema versions and stages.
    ///   - backend: The storage backend instance to migrate.
    ///   - assumeVersionIfMissing: When no schema version is found in the backend
    ///     and this value is non-`nil`, the migrator assumes the existing data
    ///     is at this version and executes all stages from that point forward.
    ///     When `nil` (the default), a missing version is treated as a fresh
    ///     install and the latest version is stamped without running any stages.
    ///
    /// - Throws: Rethrows any error thrown by a custom migration stage closure.
    ///   When an error is thrown, the schema version is **not** updated.
    public static func migrate(
        for plan: any StorageMigrationPlan.Type,
        on backend: any StorageBackend,
        assumeVersionIfMissing: StorageSchemaVersion? = nil
    ) throws {
        try performMigration(plan: plan, backend: backend, assumeVersionIfMissing: assumeVersionIfMissing)
    }

    // MARK: - Private

    private static func performMigration(
        plan: any StorageMigrationPlan.Type,
        backend: any StorageBackend,
        assumeVersionIfMissing: StorageSchemaVersion?
    ) throws {
        guard let latestSchema = plan.schemas.last else {
            return
        }

        let latestVersion = latestSchema.versionIdentifier

        // Read current version from backend
        var currentVersion = readStoredVersion(from: backend)

        // If no version is stored, handle first-launch vs upgrade-from-pre-migration
        if currentVersion == nil {
            if let assumed = assumeVersionIfMissing {
                // Treat existing data as being at the assumed version
                currentVersion = assumed
            } else {
                // First launch — stamp latest version and skip all stages
                writeStoredVersion(latestVersion, to: backend)
                return
            }
        }

        guard let currentVersion, currentVersion < latestVersion else {
            return
        }

        // Find applicable stages: those whose fromVersion >= currentVersion
        let applicableStages = plan.stages.filter { stage in
            stage.fromVersion.versionIdentifier >= currentVersion
        }.sorted { a, b in
            a.fromVersion.versionIdentifier < b.fromVersion.versionIdentifier
        }

        // Execute stages in order
        let context = StorageMigrationContext(backend: backend)
        for stage in applicableStages {
            switch stage {
            case .lightweight:
                // No-op: lightweight migration just advances the version
                break
            case .custom(_, _, let willMigrate, let didMigrate):
                try willMigrate?(context)
                try didMigrate?(context)
            }
        }

        // Stamp the new version
        writeStoredVersion(latestVersion, to: backend)
    }

    private static func readStoredVersion(from backend: any StorageBackend) -> StorageSchemaVersion? {
        let raw: String = backend.persistedValue(forKey: versionKey, default: "")
        guard !raw.isEmpty else { return nil }
        let components = raw.split(separator: ".").compactMap { Int($0) }
        guard components.count == 3 else { return nil }
        return StorageSchemaVersion(components[0], components[1], components[2])
    }

    private static func writeStoredVersion(_ version: StorageSchemaVersion, to backend: any StorageBackend) {
        backend.setPersisted(version.description, forKey: versionKey)
    }
}
#endif
