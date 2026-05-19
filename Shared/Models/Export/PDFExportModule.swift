import Foundation
import SwiftUI
import CoreGraphics
import CoreText
import UniformTypeIdentifiers

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
    static func render(_ descriptor: PDFExportDocumentDescriptor, pageSize: CGSize = CGSize(width: 595, height: 842)) throws -> Data {
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: nil, nil) else {
            throw PDFExportModuleError.unableToCreateContext
        }

        let margin: CGFloat = 36
        let contentWidth = pageSize.width - (margin * 2)

        var cursorY: CGFloat = margin

        func startPage() {
            context.beginPDFPage([kCGPDFContextMediaBox as String: CGRect(origin: .zero, size: pageSize)] as CFDictionary)
            cursorY = margin
        }

        func endPage() {
            context.endPDFPage()
        }

        startPage()

        cursorY += drawText(descriptor.title, fontSize: 20, weight: .bold, at: CGPoint(x: margin, y: cursorY), width: contentWidth, context: context)
        cursorY += 6
        cursorY += drawText(descriptor.subtitle, fontSize: 12, weight: .regular, at: CGPoint(x: margin, y: cursorY), width: contentWidth, context: context)
        cursorY += 12

        for section in descriptor.sections {
            if cursorY > pageSize.height - 120 {
                endPage()
                startPage()
            }

            cursorY += drawText(section.title, fontSize: 14, weight: .semibold, at: CGPoint(x: margin, y: cursorY), width: contentWidth, context: context)
            cursorY += 6

            for line in section.lines {
                if cursorY > pageSize.height - 80 {
                    endPage()
                    startPage()
                }

                cursorY += drawText("• \(line.title)", fontSize: 11, weight: .medium, at: CGPoint(x: margin, y: cursorY), width: contentWidth, context: context)
                if let detail = line.detail, !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    cursorY += drawText(detail, fontSize: 10, weight: .regular, at: CGPoint(x: margin + 12, y: cursorY), width: contentWidth - 12, context: context)
                }
                cursorY += 4
            }

            cursorY += 8
        }

        endPage()
        context.closePDF()
        return data as Data
    }

    private enum FontWeight {
        case regular
        case medium
        case semibold
        case bold

        var postScriptName: String {
            switch self {
            case .regular: return "Helvetica"
            case .medium: return "Helvetica"
            case .semibold: return "Helvetica-Bold"
            case .bold: return "Helvetica-Bold"
            }
        }
    }

    @discardableResult
    private static func drawText(_ text: String, fontSize: CGFloat, weight: FontWeight, at origin: CGPoint, width: CGFloat, context: CGContext) -> CGFloat {
        let font = CTFontCreateWithName(weight.postScriptName as CFString, fontSize, nil)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: CGColor(gray: 0.08, alpha: 1)
        ]

        let attrString = NSAttributedString(string: text, attributes: attrs)
        let framesetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
        let constraintSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        let suggested = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, attrString.length), nil, constraintSize, nil)

        let textHeight = ceil(suggested.height)
        let drawRect = CGRect(x: origin.x, y: origin.y, width: width, height: max(textHeight, fontSize + 2))

        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: 0, y: drawRect.maxY * 2)
        context.scaleBy(x: 1, y: -1)

        let pathRect = CGRect(x: drawRect.minX, y: drawRect.minY, width: drawRect.width, height: drawRect.height)
        let path = CGPath(rect: pathRect, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attrString.length), path, nil)
        CTFrameDraw(frame, context)

        context.restoreGState()

        return drawRect.height
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
