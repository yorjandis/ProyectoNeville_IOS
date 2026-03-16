import Foundation
import SQLite3

private let sqliteTransientDestructor = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

actor OfflineOpenFoodFactsDatabase {
    struct AvailabilityStatus: Sendable {
        let databaseURL: URL
        let didCopy: Bool
        let installedVersion: Int
    }

    struct ProductRecord: Sendable {
        let barcode: String
        let productName: String
        let brands: String?
        let quantity: String?
        let nutritionGrade: String?
        let novaGroup: Int?
        let energyKcal100g: Double?
        let proteins100g: Double?
        let fiber100g: Double?
        let saturatedFat100g: Double?
        let sugars100g: Double?
        let salt100g: Double?
        let fat100g: Double?
        let carbohydrates100g: Double?
        let imagePath: String?
        let additiveEcodes: String?
        let allergensText: String?
        let allergensTags: String?
        let tracesText: String?
        let tracesTags: String?
        let isVegan: Bool?
        let isVegetarian: Bool?
        let isOrganic: Bool?
        let hasGluten: Bool?
    }

    private let bootstrapper: DatabaseBootstrapper

    init(bootstrapper: DatabaseBootstrapper = DatabaseBootstrapper()) {
        self.bootstrapper = bootstrapper
    }

    func ensureDatabaseAvailable() async throws -> AvailabilityStatus {
        let result = try await bootstrapper.bootstrapDatabase()
        return AvailabilityStatus(
            databaseURL: result.databaseURL,
            didCopy: result.didCopy,
            installedVersion: result.installedVersion
        )
    }

    func fetchProduct(by barcode: String) async throws -> ProductRecord {
        let status = try await ensureDatabaseAvailable()
        return try queryProduct(barcode: barcode, databaseURL: status.databaseURL)
    }

    private func queryProduct(barcode: String, databaseURL: URL) throws -> ProductRecord {
        var db: OpaquePointer?
        guard sqlite3_open_v2(databaseURL.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            defer { sqlite3_close(db) }
            throw LectorEtiquetasError.baseOfflineNoDisponible
        }
        defer { sqlite3_close(db) }

        let sql = """
        SELECT barcode, product_name, brands, quantity, nutrition_grade, nova_group,
               energy_kcal_100g, proteins_100g, fiber_100g, saturated_fat_100g, sugars_100g,
               salt_100g, fat_100g, carbohydrates_100g, image_path, additive_ecodes,
               allergens_text, allergens_tags, traces_text, traces_tags,
               is_vegan, is_vegetarian, is_organic, has_gluten
        FROM products
        WHERE barcode = ?
        LIMIT 1;
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw LectorEtiquetasError.baseOfflineNoDisponible
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, barcode, -1, sqliteTransientDestructor)

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw LectorEtiquetasError.productoNoEncontradoEnBaseOffline
        }

        return ProductRecord(
            barcode: stringColumn(statement, index: 0) ?? barcode,
            productName: stringColumn(statement, index: 1) ?? "Producto sin nombre",
            brands: stringColumn(statement, index: 2),
            quantity: stringColumn(statement, index: 3),
            nutritionGrade: stringColumn(statement, index: 4),
            novaGroup: intColumn(statement, index: 5),
            energyKcal100g: doubleColumn(statement, index: 6),
            proteins100g: doubleColumn(statement, index: 7),
            fiber100g: doubleColumn(statement, index: 8),
            saturatedFat100g: doubleColumn(statement, index: 9),
            sugars100g: doubleColumn(statement, index: 10),
            salt100g: doubleColumn(statement, index: 11),
            fat100g: doubleColumn(statement, index: 12),
            carbohydrates100g: doubleColumn(statement, index: 13),
            imagePath: stringColumn(statement, index: 14),
            additiveEcodes: stringColumn(statement, index: 15),
            allergensText: stringColumn(statement, index: 16),
            allergensTags: stringColumn(statement, index: 17),
            tracesText: stringColumn(statement, index: 18),
            tracesTags: stringColumn(statement, index: 19),
            isVegan: boolColumn(statement, index: 20),
            isVegetarian: boolColumn(statement, index: 21),
            isOrganic: boolColumn(statement, index: 22),
            hasGluten: boolColumn(statement, index: 23)
        )
    }

    private func stringColumn(_ statement: OpaquePointer?, index: Int32) -> String? {
        guard let cString = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: cString).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func intColumn(_ statement: OpaquePointer?, index: Int32) -> Int? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else { return nil }
        return Int(sqlite3_column_int(statement, index))
    }

    private func doubleColumn(_ statement: OpaquePointer?, index: Int32) -> Double? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else { return nil }
        return sqlite3_column_double(statement, index)
    }

    private func boolColumn(_ statement: OpaquePointer?, index: Int32) -> Bool? {
        guard let value = intColumn(statement, index: index) else { return nil }
        return value != 0
    }
}
