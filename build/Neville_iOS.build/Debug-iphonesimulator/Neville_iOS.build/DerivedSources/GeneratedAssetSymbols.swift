import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "Icon-29" asset catalog image resource.
    static let icon29 = DeveloperToolsSupport.ImageResource(name: "Icon-29", bundle: resourceBundle)

    /// The "Logo" asset catalog image resource.
    static let logo = DeveloperToolsSupport.ImageResource(name: "Logo", bundle: resourceBundle)

    /// The "ad-min" asset catalog image resource.
    static let adMin = DeveloperToolsSupport.ImageResource(name: "ad-min", bundle: resourceBundle)

    /// The "bruce" asset catalog image resource.
    static let bruce = DeveloperToolsSupport.ImageResource(name: "bruce", bundle: resourceBundle)

    /// The "celdasLogo" asset catalog image resource.
    static let celdasLogo = DeveloperToolsSupport.ImageResource(name: "celdasLogo", bundle: resourceBundle)

    /// The "desanimado" asset catalog image resource.
    static let desanimado = DeveloperToolsSupport.ImageResource(name: "desanimado", bundle: resourceBundle)

    /// The "distraido" asset catalog image resource.
    static let distraido = DeveloperToolsSupport.ImageResource(name: "distraido", bundle: resourceBundle)

    /// The "enfadado" asset catalog image resource.
    static let enfadado = DeveloperToolsSupport.ImageResource(name: "enfadado", bundle: resourceBundle)

    /// The "escritor" asset catalog image resource.
    static let escritor = DeveloperToolsSupport.ImageResource(name: "escritor", bundle: resourceBundle)

    /// The "feliz" asset catalog image resource.
    static let feliz = DeveloperToolsSupport.ImageResource(name: "feliz", bundle: resourceBundle)

    /// The "fondo" asset catalog image resource.
    static let fondo = DeveloperToolsSupport.ImageResource(name: "fondo", bundle: resourceBundle)

    /// The "green-score-a" asset catalog image resource.
    static let greenScoreA = DeveloperToolsSupport.ImageResource(name: "green-score-a", bundle: resourceBundle)

    /// The "green-score-a-plus" asset catalog image resource.
    static let greenScoreAPlus = DeveloperToolsSupport.ImageResource(name: "green-score-a-plus", bundle: resourceBundle)

    /// The "green-score-b" asset catalog image resource.
    static let greenScoreB = DeveloperToolsSupport.ImageResource(name: "green-score-b", bundle: resourceBundle)

    /// The "green-score-c" asset catalog image resource.
    static let greenScoreC = DeveloperToolsSupport.ImageResource(name: "green-score-c", bundle: resourceBundle)

    /// The "green-score-d" asset catalog image resource.
    static let greenScoreD = DeveloperToolsSupport.ImageResource(name: "green-score-d", bundle: resourceBundle)

    /// The "green-score-e" asset catalog image resource.
    static let greenScoreE = DeveloperToolsSupport.ImageResource(name: "green-score-e", bundle: resourceBundle)

    /// The "green-score-f" asset catalog image resource.
    static let greenScoreF = DeveloperToolsSupport.ImageResource(name: "green-score-f", bundle: resourceBundle)

    /// The "green-score-unknown" asset catalog image resource.
    static let greenScoreUnknown = DeveloperToolsSupport.ImageResource(name: "green-score-unknown", bundle: resourceBundle)

    /// The "gregg" asset catalog image resource.
    static let gregg = DeveloperToolsSupport.ImageResource(name: "gregg", bundle: resourceBundle)

    /// The "jd" asset catalog image resource.
    static let jd = DeveloperToolsSupport.ImageResource(name: "jd", bundle: resourceBundle)

    /// The "neutral" asset catalog image resource.
    static let neutral = DeveloperToolsSupport.ImageResource(name: "neutral", bundle: resourceBundle)

    /// The "nev-min" asset catalog image resource.
    static let nevMin = DeveloperToolsSupport.ImageResource(name: "nev-min", bundle: resourceBundle)

    /// The "nutriscore_a" asset catalog image resource.
    static let nutriscoreA = DeveloperToolsSupport.ImageResource(name: "nutriscore_a", bundle: resourceBundle)

    /// The "nutriscore_b" asset catalog image resource.
    static let nutriscoreB = DeveloperToolsSupport.ImageResource(name: "nutriscore_b", bundle: resourceBundle)

    /// The "nutriscore_c" asset catalog image resource.
    static let nutriscoreC = DeveloperToolsSupport.ImageResource(name: "nutriscore_c", bundle: resourceBundle)

    /// The "nutriscore_d" asset catalog image resource.
    static let nutriscoreD = DeveloperToolsSupport.ImageResource(name: "nutriscore_d", bundle: resourceBundle)

    /// The "nutriscore_nd" asset catalog image resource.
    static let nutriscoreNd = DeveloperToolsSupport.ImageResource(name: "nutriscore_nd", bundle: resourceBundle)

    /// The "p_75porciento" asset catalog image resource.
    static let p75Porciento = DeveloperToolsSupport.ImageResource(name: "p_75porciento", bundle: resourceBundle)

    /// The "p_completed" asset catalog image resource.
    static let pCompleted = DeveloperToolsSupport.ImageResource(name: "p_completed", bundle: resourceBundle)

    /// The "p_diario2" asset catalog image resource.
    static let pDiario2 = DeveloperToolsSupport.ImageResource(name: "p_diario2", bundle: resourceBundle)

    /// The "p_diarioOff" asset catalog image resource.
    static let pDiarioOff = DeveloperToolsSupport.ImageResource(name: "p_diarioOff", bundle: resourceBundle)

    /// The "p_normal" asset catalog image resource.
    static let pNormal = DeveloperToolsSupport.ImageResource(name: "p_normal", bundle: resourceBundle)

    /// The "salud" asset catalog image resource.
    static let salud = DeveloperToolsSupport.ImageResource(name: "salud", bundle: resourceBundle)

    /// The "sorpresa" asset catalog image resource.
    static let sorpresa = DeveloperToolsSupport.ImageResource(name: "sorpresa", bundle: resourceBundle)

    /// The "william" asset catalog image resource.
    static let william = DeveloperToolsSupport.ImageResource(name: "william", bundle: resourceBundle)

    /// The "yorj" asset catalog image resource.
    static let yorj = DeveloperToolsSupport.ImageResource(name: "yorj", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AccentColor" asset catalog color.
    static var accent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accent)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AccentColor" asset catalog color.
    static var accent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accent)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "Icon-29" asset catalog image.
    static var icon29: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icon29)
#else
        .init()
#endif
    }

    /// The "Logo" asset catalog image.
    static var logo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .logo)
#else
        .init()
#endif
    }

    /// The "ad-min" asset catalog image.
    static var adMin: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .adMin)
#else
        .init()
#endif
    }

    /// The "bruce" asset catalog image.
    static var bruce: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bruce)
#else
        .init()
#endif
    }

    /// The "celdasLogo" asset catalog image.
    static var celdasLogo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .celdasLogo)
#else
        .init()
#endif
    }

    /// The "desanimado" asset catalog image.
    static var desanimado: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desanimado)
#else
        .init()
#endif
    }

    /// The "distraido" asset catalog image.
    static var distraido: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .distraido)
#else
        .init()
#endif
    }

    /// The "enfadado" asset catalog image.
    static var enfadado: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .enfadado)
#else
        .init()
#endif
    }

    /// The "escritor" asset catalog image.
    static var escritor: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .escritor)
#else
        .init()
#endif
    }

    /// The "feliz" asset catalog image.
    static var feliz: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .feliz)
#else
        .init()
#endif
    }

    /// The "fondo" asset catalog image.
    static var fondo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .fondo)
#else
        .init()
#endif
    }

    /// The "green-score-a" asset catalog image.
    static var greenScoreA: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .greenScoreA)
#else
        .init()
#endif
    }

    /// The "green-score-a-plus" asset catalog image.
    static var greenScoreAPlus: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .greenScoreAPlus)
#else
        .init()
#endif
    }

    /// The "green-score-b" asset catalog image.
    static var greenScoreB: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .greenScoreB)
#else
        .init()
#endif
    }

    /// The "green-score-c" asset catalog image.
    static var greenScoreC: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .greenScoreC)
#else
        .init()
#endif
    }

    /// The "green-score-d" asset catalog image.
    static var greenScoreD: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .greenScoreD)
#else
        .init()
#endif
    }

    /// The "green-score-e" asset catalog image.
    static var greenScoreE: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .greenScoreE)
#else
        .init()
#endif
    }

    /// The "green-score-f" asset catalog image.
    static var greenScoreF: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .greenScoreF)
#else
        .init()
#endif
    }

    /// The "green-score-unknown" asset catalog image.
    static var greenScoreUnknown: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .greenScoreUnknown)
#else
        .init()
#endif
    }

    /// The "gregg" asset catalog image.
    static var gregg: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .gregg)
#else
        .init()
#endif
    }

    /// The "jd" asset catalog image.
    static var jd: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jd)
#else
        .init()
#endif
    }

    /// The "neutral" asset catalog image.
    static var neutral: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .neutral)
#else
        .init()
#endif
    }

    /// The "nev-min" asset catalog image.
    static var nevMin: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .nevMin)
#else
        .init()
#endif
    }

    /// The "nutriscore_a" asset catalog image.
    static var nutriscoreA: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .nutriscoreA)
#else
        .init()
#endif
    }

    /// The "nutriscore_b" asset catalog image.
    static var nutriscoreB: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .nutriscoreB)
#else
        .init()
#endif
    }

    /// The "nutriscore_c" asset catalog image.
    static var nutriscoreC: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .nutriscoreC)
#else
        .init()
#endif
    }

    /// The "nutriscore_d" asset catalog image.
    static var nutriscoreD: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .nutriscoreD)
#else
        .init()
#endif
    }

    /// The "nutriscore_nd" asset catalog image.
    static var nutriscoreNd: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .nutriscoreNd)
#else
        .init()
#endif
    }

    /// The "p_75porciento" asset catalog image.
    static var p75Porciento: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p75Porciento)
#else
        .init()
#endif
    }

    /// The "p_completed" asset catalog image.
    static var pCompleted: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pCompleted)
#else
        .init()
#endif
    }

    /// The "p_diario2" asset catalog image.
    static var pDiario2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pDiario2)
#else
        .init()
#endif
    }

    /// The "p_diarioOff" asset catalog image.
    static var pDiarioOff: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pDiarioOff)
#else
        .init()
#endif
    }

    /// The "p_normal" asset catalog image.
    static var pNormal: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pNormal)
#else
        .init()
#endif
    }

    /// The "salud" asset catalog image.
    static var salud: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .salud)
#else
        .init()
#endif
    }

    /// The "sorpresa" asset catalog image.
    static var sorpresa: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .sorpresa)
#else
        .init()
#endif
    }

    /// The "william" asset catalog image.
    static var william: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .william)
#else
        .init()
#endif
    }

    /// The "yorj" asset catalog image.
    static var yorj: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .yorj)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "Icon-29" asset catalog image.
    static var icon29: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icon29)
#else
        .init()
#endif
    }

    /// The "Logo" asset catalog image.
    static var logo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .logo)
#else
        .init()
#endif
    }

    /// The "ad-min" asset catalog image.
    static var adMin: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .adMin)
#else
        .init()
#endif
    }

    /// The "bruce" asset catalog image.
    static var bruce: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bruce)
#else
        .init()
#endif
    }

    /// The "celdasLogo" asset catalog image.
    static var celdasLogo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .celdasLogo)
#else
        .init()
#endif
    }

    /// The "desanimado" asset catalog image.
    static var desanimado: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desanimado)
#else
        .init()
#endif
    }

    /// The "distraido" asset catalog image.
    static var distraido: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .distraido)
#else
        .init()
#endif
    }

    /// The "enfadado" asset catalog image.
    static var enfadado: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .enfadado)
#else
        .init()
#endif
    }

    /// The "escritor" asset catalog image.
    static var escritor: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .escritor)
#else
        .init()
#endif
    }

    /// The "feliz" asset catalog image.
    static var feliz: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .feliz)
#else
        .init()
#endif
    }

    /// The "fondo" asset catalog image.
    static var fondo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .fondo)
#else
        .init()
#endif
    }

    /// The "green-score-a" asset catalog image.
    static var greenScoreA: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .greenScoreA)
#else
        .init()
#endif
    }

    /// The "green-score-a-plus" asset catalog image.
    static var greenScoreAPlus: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .greenScoreAPlus)
#else
        .init()
#endif
    }

    /// The "green-score-b" asset catalog image.
    static var greenScoreB: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .greenScoreB)
#else
        .init()
#endif
    }

    /// The "green-score-c" asset catalog image.
    static var greenScoreC: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .greenScoreC)
#else
        .init()
#endif
    }

    /// The "green-score-d" asset catalog image.
    static var greenScoreD: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .greenScoreD)
#else
        .init()
#endif
    }

    /// The "green-score-e" asset catalog image.
    static var greenScoreE: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .greenScoreE)
#else
        .init()
#endif
    }

    /// The "green-score-f" asset catalog image.
    static var greenScoreF: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .greenScoreF)
#else
        .init()
#endif
    }

    /// The "green-score-unknown" asset catalog image.
    static var greenScoreUnknown: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .greenScoreUnknown)
#else
        .init()
#endif
    }

    /// The "gregg" asset catalog image.
    static var gregg: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .gregg)
#else
        .init()
#endif
    }

    /// The "jd" asset catalog image.
    static var jd: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jd)
#else
        .init()
#endif
    }

    /// The "neutral" asset catalog image.
    static var neutral: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .neutral)
#else
        .init()
#endif
    }

    /// The "nev-min" asset catalog image.
    static var nevMin: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .nevMin)
#else
        .init()
#endif
    }

    /// The "nutriscore_a" asset catalog image.
    static var nutriscoreA: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .nutriscoreA)
#else
        .init()
#endif
    }

    /// The "nutriscore_b" asset catalog image.
    static var nutriscoreB: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .nutriscoreB)
#else
        .init()
#endif
    }

    /// The "nutriscore_c" asset catalog image.
    static var nutriscoreC: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .nutriscoreC)
#else
        .init()
#endif
    }

    /// The "nutriscore_d" asset catalog image.
    static var nutriscoreD: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .nutriscoreD)
#else
        .init()
#endif
    }

    /// The "nutriscore_nd" asset catalog image.
    static var nutriscoreNd: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .nutriscoreNd)
#else
        .init()
#endif
    }

    /// The "p_75porciento" asset catalog image.
    static var p75Porciento: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p75Porciento)
#else
        .init()
#endif
    }

    /// The "p_completed" asset catalog image.
    static var pCompleted: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pCompleted)
#else
        .init()
#endif
    }

    /// The "p_diario2" asset catalog image.
    static var pDiario2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pDiario2)
#else
        .init()
#endif
    }

    /// The "p_diarioOff" asset catalog image.
    static var pDiarioOff: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pDiarioOff)
#else
        .init()
#endif
    }

    /// The "p_normal" asset catalog image.
    static var pNormal: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pNormal)
#else
        .init()
#endif
    }

    /// The "salud" asset catalog image.
    static var salud: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .salud)
#else
        .init()
#endif
    }

    /// The "sorpresa" asset catalog image.
    static var sorpresa: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .sorpresa)
#else
        .init()
#endif
    }

    /// The "william" asset catalog image.
    static var william: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .william)
#else
        .init()
#endif
    }

    /// The "yorj" asset catalog image.
    static var yorj: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .yorj)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

