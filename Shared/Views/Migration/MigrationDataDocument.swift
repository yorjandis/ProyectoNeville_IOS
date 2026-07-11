import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    nonisolated static let ypgExport = UTType(exportedAs: "com.ypg.neville.ypgexp")
}

struct MigrationDataDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.ypgExport] }
    static var writableContentTypes: [UTType] { [.ypgExport] }

    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
