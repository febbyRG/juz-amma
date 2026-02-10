//
//  JuzAmmaMigrationPlan.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 10/02/26.
//

import SwiftData

// MARK: - Schema Versions

/// Initial schema version capturing the current data model
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Surah.self, Ayah.self, AppSettings.self, Translation.self]
    }
}

// MARK: - Migration Plan

/// Manages schema migrations across app updates
/// Add new VersionedSchema versions and migration stages as the data model evolves
enum JuzAmmaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }
    
    static var stages: [MigrationStage] {
        // No migrations yet — add stages here when schema changes
        // Example for future use:
        // .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
        []
    }
}
