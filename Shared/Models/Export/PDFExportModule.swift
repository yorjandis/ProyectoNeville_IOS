import Foundation
import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import TPPDF

struct PDFExportLine: Hashable {
    let title: String
    let detail: String?
}

struct PDFExportSection: Hashable {
    let title: String
    let lines: [PDFExportLine]
}

struct PDFExportDocumentDescriptor: Hashable {
    let title: String
    let subtitle: String
    let sections: [PDFExportSection]
}

enum PDFExportModuleError: Error {
    case unableToCreateContext
}

enum PDFExportModule {
    static func render(
        _ descriptor: PDFExportDocumentDescriptor,
        pageSize: CGSize = CGSize(width: 595, height: 842),
        useBlueSectionBullets: Bool = false
    ) throws -> Data {
        try render(title: descriptor.title, subtitle: descriptor.subtitle, pageSize: pageSize) { document in
            addAgendaLikeBody(descriptor.sections, to: document, useBlueSectionBullets: useBlueSectionBullets)
        }
    }

    static func render(
        title: String,
        subtitle: String,
        pageSize: CGSize = CGSize(width: 595, height: 842),
        contentBuilder: (PDFDocument) -> Void
    ) throws -> Data {
        _ = pageSize
        let document = PDFDocument(format: .a4)
        document.info.title = title
        document.info.author = "La Ley"
        document.info.subject = subtitle
        document.layout.margin = EdgeInsets(top: 36, left: 36, bottom: 44, right: 36)
        document.layout.space.footer = 8

        addHeader(to: document)
        addGlobalFooter(to: document)
        addDefaultDocumentHeading(title: title, subtitle: subtitle, to: document)
        contentBuilder(document)

        let generator = PDFGenerator(document: document)
        let outputURL = try generator.generateURL(filename: "Agenda-La-Ley.pdf")
        return try Data(contentsOf: outputURL)
    }

    private static func addHeader(to document: PDFDocument) {
        if let logoEntry = makeRoundedLogoImage(size: CGSize(width: 84, height: 84), cornerRadius: 42) {
            document.add(.contentCenter, image: logoEntry)
        }
        document.add(.contentCenter, space: 10)
        document.set(.contentCenter, font: headerFont())
        document.add(.contentCenter, text: "La Ley", lineSpacing: 2)
        document.add(.contentCenter, space: 20)
    }

    private static func addGlobalFooter(to document: PDFDocument) {
        if let brand = footerBrandAttributedText() {
            document.add(.footerLeft, attributedText: brand)
        } else {
            document.set(.footerLeft, font: footerFont())
            document.add(.footerLeft, text: "La Ley", lineSpacing: 1)
        }
        document.add(.footerLeft, space: 4)
        let footerSeparatorStyle = PDFLineStyle(type: .full, color: footerSeparatorColor(), width: 0.6)
        document.addLineSeparator(.footerCenter, style: footerSeparatorStyle)
    }

    private static func addDefaultDocumentHeading(title: String, subtitle: String, to document: PDFDocument) {
        document.set(.contentLeft, font: titleFont())
        document.add(.contentLeft, text: title, lineSpacing: 3)
        document.add(.contentLeft, space: 8)

        document.set(.contentLeft, font: subtitleFont())
        document.add(.contentLeft, text: subtitle, lineSpacing: 2)
        document.add(.contentLeft, space: 16)
    }

    private static func addAgendaLikeBody(
        _ sections: [PDFExportSection],
        to document: PDFDocument,
        useBlueSectionBullets: Bool
    ) {
        for section in sections {
            document.set(.contentLeft, font: sectionFont())
            let sectionPrefix = useBlueSectionBullets ? "🔵 " : ""
            document.add(.contentLeft, text: "\(sectionPrefix)\(section.title)", lineSpacing: 2)
            document.add(.contentLeft, space: 8)

            for line in section.lines {
                document.set(.contentLeft, font: lineTitleFont())
                document.add(.contentLeft, text: "• \(line.title)", lineSpacing: 2)

                if let detail = line.detail?.trimmingCharacters(in: .whitespacesAndNewlines), !detail.isEmpty {
                    document.set(.contentLeft, indent: 12, left: true)
                    document.set(.contentLeft, font: lineDetailFont())
                    document.add(.contentLeft, text: detail, lineSpacing: 2)
                    document.set(.contentLeft, indent: 0, left: true)
                }
                document.add(.contentLeft, space: 8)
            }

            document.add(.contentLeft, space: 10)
        }
    }

#if canImport(UIKit)
    private static func headerFont() -> UIFont {
        UIFont.boldSystemFont(ofSize: 20)
    }
#elseif canImport(AppKit)
    private static func headerFont() -> NSFont {
        NSFont.boldSystemFont(ofSize: 20)
    }
#endif

#if canImport(UIKit)
    private static func titleFont() -> UIFont {
        UIFont.boldSystemFont(ofSize: 20)
    }
#elseif canImport(AppKit)
    private static func titleFont() -> NSFont {
        NSFont.boldSystemFont(ofSize: 20)
    }
#endif

#if canImport(UIKit)
    private static func subtitleFont() -> UIFont {
        UIFont.systemFont(ofSize: 12)
    }
#elseif canImport(AppKit)
    private static func subtitleFont() -> NSFont {
        NSFont.systemFont(ofSize: 12)
    }
#endif

#if canImport(UIKit)
    private static func sectionFont() -> UIFont {
        UIFont.boldSystemFont(ofSize: 14)
    }
#elseif canImport(AppKit)
    private static func sectionFont() -> NSFont {
        NSFont.boldSystemFont(ofSize: 14)
    }
#endif

#if canImport(UIKit)
    private static func lineTitleFont() -> UIFont {
        UIFont.systemFont(ofSize: 11, weight: .medium)
    }
#elseif canImport(AppKit)
    private static func lineTitleFont() -> NSFont {
        NSFont.systemFont(ofSize: 11, weight: .medium)
    }
#endif

#if canImport(UIKit)
    private static func lineDetailFont() -> UIFont {
        UIFont.systemFont(ofSize: 10)
    }
#elseif canImport(AppKit)
    private static func lineDetailFont() -> NSFont {
        NSFont.systemFont(ofSize: 10)
    }
#endif

    #if canImport(UIKit)
    private static func footerFont() -> UIFont {
        UIFont.systemFont(ofSize: 9, weight: .semibold)
    }

    private static func footerSeparatorColor() -> UIColor {
        UIColor(white: 0.75, alpha: 1)
    }
    #elseif canImport(AppKit)
    private static func footerFont() -> NSFont {
        NSFont.systemFont(ofSize: 9, weight: .semibold)
    }

    private static func footerSeparatorColor() -> NSColor {
        NSColor(white: 0.75, alpha: 1)
    }
    #endif

#if canImport(UIKit)
    private static func loadLogoImage() -> UIImage? {
        if let image = UIImage(named: "Logo") {
            return image
        }
        if let image = UIImage(named: "logo") {
            return image
        }
        return nil
    }
#elseif canImport(AppKit)
    private static func loadLogoImage() -> NSImage? {
        if let image = NSImage(named: "Logo") {
            return image
        }
        if let image = NSImage(named: "logo") {
            return image
        }
        return nil
    }
#endif

    private static func makeRoundedLogoImage(size: CGSize, cornerRadius: CGFloat) -> PDFImage? {
        guard let logo = loadLogoImage() else {
            return nil
        }
        return PDFImage(
            image: logo,
            size: size,
            options: [.resize, .compress, .rounded],
            cornerRadius: cornerRadius
        )
    }

    private static func footerBrandAttributedText() -> NSAttributedString? {
        let attributed = NSMutableAttributedString()

        #if canImport(UIKit)
        if let logo = loadLogoImage() {
            let attachment = NSTextAttachment()
            attachment.image = logo
            attachment.bounds = CGRect(x: 0, y: -2, width: 10, height: 10)
            attributed.append(NSAttributedString(attachment: attachment))
            attributed.append(NSAttributedString(string: " "))
        }
        let attrs: [NSAttributedString.Key: Any] = [
            .font: footerFont(),
            .foregroundColor: UIColor(white: 0.15, alpha: 1)
        ]
        attributed.append(NSAttributedString(string: "La Ley", attributes: attrs))
        #elseif canImport(AppKit)
        if let logo = loadLogoImage() {
            let attachment = NSTextAttachment()
            let imageCell = NSTextAttachmentCell(imageCell: logo)
            attachment.attachmentCell = imageCell
            attributed.append(NSAttributedString(attachment: attachment))
            attributed.append(NSAttributedString(string: " "))
        }
        let attrs: [NSAttributedString.Key: Any] = [
            .font: footerFont(),
            .foregroundColor: NSColor(white: 0.15, alpha: 1)
        ]
        attributed.append(NSAttributedString(string: "La Ley", attributes: attrs))
        #endif

        return attributed.length > 0 ? attributed : nil
    }
}

struct ExportedPDFDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
