//
//  OpenFoodFactsClient.swift
//  Neville_iOS
//
//  Created by Codex on 13/03/26.
//

import Foundation

struct OpenFoodFactsClient {
    private let baseURL = "https://world.openfoodfacts.org/api/v2/product"

    func fetchProduct(by barcode: String) async throws -> OpenFoodFactsPayload {
        guard let url = makeURL(for: barcode) else {
            throw LectorEtiquetasError.codigoBarrasInvalido
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Neville_iOS - LectorEtiquetas", forHTTPHeaderField: "User-Agent")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw LectorEtiquetasError.redOpenFoodFacts(error)
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw LectorEtiquetasError.respuestaOpenFoodFactsInvalida
        }

        #if DEBUG
        if let rawResponse = String(data: data, encoding: .utf8) {
            print("[OpenFoodFacts][RAW][\(barcode)] \(rawResponse)")
        } else {
            print("[OpenFoodFacts][RAW][\(barcode)] <respuesta no UTF-8>")
        }
        #endif

        let decoded: OpenFoodFactsResponse
        do {
            decoded = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
        } catch {
            throw LectorEtiquetasError.respuestaOpenFoodFactsInvalida
        }

        guard decoded.status == 1, let product = decoded.product else {
            throw LectorEtiquetasError.productoNoEncontradoEnOpenFoodFacts
        }

        let allFields = extractOrderedFields(from: data)
        let nutriments = extractNutrimentsFormatted(from: data)

        return OpenFoodFactsPayload(product: product, allFields: allFields, nutrimentsFormatted: nutriments)
    }

    private func makeURL(for barcode: String) -> URL? {
        var comps = URLComponents(string: "\(baseURL)/\(barcode)")
        comps?.queryItems = [
            URLQueryItem(name: "fields", value: "code,product_name,brands,categories,quantity,allergens,ingredients_text,ingredients_analysis_tags,nutriments,nutriscore_grade,nova_group,ecoscore_grade,labels,labels_tags,countries,countries_tags,origins,origins_tags,certifications,certifications_tags,image_url,image_front_url")
        ]
        return comps?.url
    }

    private func extractOrderedFields(from data: Data) -> [OpenFoodFactsFieldItem] {
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let product = root["product"] as? [String: Any] else {
            return []
        }

        let preferredOrder = ["code", "allergens", "ingredients_text"]
        var fields: [OpenFoodFactsFieldItem] = []

        for key in preferredOrder {
            if key == "nutriments" { continue }
            if let value = product[key], let text = stringify(value) {
                fields.append(OpenFoodFactsFieldItem(key: key, value: text))
            }
        }

        let remainingKeys = product.keys
            .filter { !preferredOrder.contains($0) && $0 != "nutriments" }
            .sorted()

        for key in remainingKeys {
            guard let value = product[key], let text = stringify(value) else { continue }
            fields.append(OpenFoodFactsFieldItem(key: key, value: text))
        }

        return fields
    }

    private func extractNutrimentsFormatted(from data: Data) -> [OpenFoodFactsNutrimentItem] {
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let product = root["product"] as? [String: Any],
              let nutriments = product["nutriments"] as? [String: Any] else {
            return []
        }

        var unitsByBase: [String: String] = [:]
        for (key, value) in nutriments {
            guard key.hasSuffix("_unit"), let unit = value as? String else { continue }
            unitsByBase[String(key.dropLast(5))] = unit
        }

        var items: [OpenFoodFactsNutrimentItem] = []

        for (key, value) in nutriments.sorted(by: { $0.key < $1.key }) {
            if key.hasSuffix("_unit") { continue }

            guard let valueText = formatNutrimentValue(value) else { continue }
            let baseKey = normalizedNutrimentBase(for: key)
            let unit = unitsByBase[baseKey]?.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalValue = (unit == nil || unit?.isEmpty == true) ? valueText : "\(valueText) \(unit!)"

            items.append(
                OpenFoodFactsNutrimentItem(
                    key: key,
                    displayName: humanReadableNutrimentName(key),
                    valueText: finalValue
                )
            )
        }

        return items
    }

    private func normalizedNutrimentBase(for key: String) -> String {
        if key.hasSuffix("_100g") { return String(key.dropLast(5)) }
        if key.hasSuffix("_serving") { return String(key.dropLast(8)) }
        if key.hasSuffix("_value") { return String(key.dropLast(6)) }
        return key
    }

    private func humanReadableNutrimentName(_ key: String) -> String {
        key
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }

    private func formatNutrimentValue(_ value: Any) -> String? {
        if let number = value as? NSNumber {
            let doubleValue = number.doubleValue
            let formatted = String(format: "%.4f", doubleValue)
            return trimTrailingZeros(formatted)
        }

        if let str = value as? String {
            let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        return nil
    }

    private func trimTrailingZeros(_ value: String) -> String {
        var result = value
        while result.contains(".") && (result.hasSuffix("0") || result.hasSuffix(".")) {
            result.removeLast()
            if result.hasSuffix(".") {
                result.removeLast()
                break
            }
        }
        return result
    }

    private func stringify(_ value: Any) -> String? {
        switch value {
        case let str as String:
            let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        case let number as NSNumber:
            return number.stringValue
        case let arr as [Any]:
            let items = arr.compactMap { stringify($0) }
            return items.isEmpty ? nil : items.joined(separator: ", ")
        case let dict as [String: Any]:
            guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]),
                  let json = String(data: data, encoding: .utf8) else {
                return nil
            }
            return json
        default:
            return nil
        }
    }
}

struct OpenFoodFactsPayload {
    let product: OpenFoodFactsProduct
    let allFields: [OpenFoodFactsFieldItem]
    let nutrimentsFormatted: [OpenFoodFactsNutrimentItem]
}

struct OpenFoodFactsResponse: Decodable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

struct OpenFoodFactsProduct: Decodable {
    let code: String?
    let productName: String?
    let ingredientsText: String?
    let allergens: String?
    let nutriments: OpenFoodFactsNutriments?
    let labels: String?
    let labelsTags: [String]?
    let ingredientsAnalysisTags: [String]?
    let countries: String?
    let countriesTags: [String]?
    let origins: String?
    let originsTags: [String]?
    let certifications: String?
    let certificationsTags: [String]?
    let ecoscoreGrade: String?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case ingredientsText = "ingredients_text"
        case allergens
        case nutriments
        case labels
        case labelsTags = "labels_tags"
        case ingredientsAnalysisTags = "ingredients_analysis_tags"
        case countries
        case countriesTags = "countries_tags"
        case origins
        case originsTags = "origins_tags"
        case certifications
        case certificationsTags = "certifications_tags"
        case ecoscoreGrade = "ecoscore_grade"
    }
}

struct OpenFoodFactsNutriments: Decodable {
    let sugars100g: Double?
    let sugarsServing: Double?
    let sugarsUnit: String?

    let salt100g: Double?
    let saltServing: Double?
    let saltUnit: String?

    let saturatedFat100g: Double?
    let saturatedFatServing: Double?
    let saturatedFatUnit: String?

    let sodium100g: Double?
    let sodiumServing: Double?
    let sodiumUnit: String?

    enum CodingKeys: String, CodingKey {
        case sugars100g = "sugars_100g"
        case sugarsServing = "sugars_serving"
        case sugarsUnit = "sugars_unit"

        case salt100g = "salt_100g"
        case saltServing = "salt_serving"
        case saltUnit = "salt_unit"

        case saturatedFat100g = "saturated-fat_100g"
        case saturatedFatServing = "saturated-fat_serving"
        case saturatedFatUnit = "saturated-fat_unit"

        case sodium100g = "sodium_100g"
        case sodiumServing = "sodium_serving"
        case sodiumUnit = "sodium_unit"
    }
}

struct AdditivesTitleCatalog {
    static let titles: [String] = [
        "Curcumin / Turmeric",
        "Cholic acid",
        "Choline salts and esters",
        "Riboflavin (Vitamin B2)",
        "Riboflavin-5'-Phosphate",
        "Tartrazine",
        "Alkannin",
        "Quinoline Yellow",
        "Fast Yellow AB",
        "Riboflavin-5-Sodium Phosphate",
        "Yellow 2G",
        "Sunset Yellow FCF",
        "Amylases",
        "Proteases",
        "Glucose oxidase",
        "Invertases",
        "Lipases",
        "Lysozyme",
        "Orange GGN",
        "Cochineal or Carminic Acid",
        "Polydextroses",
        "Polyvinylpyrrolidone",
        "Polyvinylpolypyrrolidone",
        "Polyvinyl alcohol",
        "Pullulan",
        "Basic methacrylate copolymer",
        "Vinyl Acetate Copolymer",
        "Polyvinyl alcohol graft copolymer",
        "Citrus Red 2",
        "Azorubine",
        "Amaranth",
        "Cochineal Red A",
        "Scarlet GN",
        "Ponceau 6R",
        "Erythrosine BS",
        "Red 2G",
        "Allura red AC",
        "Indanthrone blue",
        "Patent Blue V",
        "Indigo Carmine",
        "Brilliant Blue FCF",
        "Chlorophyll",
        "Dextrins, roasted starch",
        "Acid-treated starch",
        "Alkaline treated starch",
        "Bleached starch",
        "Oxidized starch",
        "Starches, enzyme treated",
        "Copper Complex of Chlorophyll",
        "Monostarch phosphate",
        "Distarch glycerol",
        "Distarch phosphate",
        "Phosphated distarch phosphate",
        "Acetylated distarch phosphate",
        "Green S",
        "Starch acetate",
        "Starch acetate esterified with vinyl acetate",
        "Acetylated distarch adipate",
        "Acetylated distarch glycerol",
        "Fast Green FCF",
        "Distarch glycerine (stabiliser)",
        "Hydroxypropyl starch",
        "Hydoxypropyl di-starch glycerol",
        "Hydroxypropyl distarch phosphate",
        "Hydroxy propyl distarch glycerol",
        "Starch sodium octenyl succinate",
        "Acetylated oxidised starch",
        "Starch aluminium octenyl succinate",
        "Plain caramel",
        "Benzylated hydrocarbons",
        "Butane-1,3-diol",
        "Castor oil",
        "Ethyl acetate",
        "Triethyl citrate",
        "Plain caramel",
        "Caustic sulfite caramel",
        "Ammonia caramel",
        "Sulfite ammonia caramel",
        "Black PN",
        "Ethanol",
        "Glycerol monoacetate",
        "Glycerol diacetate",
        "Triacetin",
        "Benzyl alcohol",
        "Black 7984",
        "Propylene glycol",
        "Polyethylene glycol",
        "Calcium lignosulfonate",
        "Hydroxyethyl cellulose",
        "Carbon Black",
        "Brown FK",
        "Brown HT",
        "Alpha, Beta, Gamma Carotene",
        "Annatto, Bixin, Norbixin",
        "Capsanthin or Capsorbin",
        "Lycopene",
        "Ã-Apo-8'-carotenal",
        "Ethyl ester of Beta-apo-8-cartonoic acid",
        "Flavoxanthin",
        "Lutein",
        "Cryptoxanthin",
        "Rubixanthin",
        "Violaxanthin",
        "Rhodoxanthin",
        "Canthaxanthin",
        "Citranaxanthin",
        "Citranaxanthin",
        "Astaxanthin",
        "Beetroot Red / Betanin",
        "Anthocyanins",
        "Cyanidin",
        "Delphinidin",
        "Malvidin",
        "Pelargonidin",
        "Petunidin",
        "Gardenia yellow",
        "Blue Gardenia",
        "Sandalwood",
        "Calcium Carbonate",
        "Titanium Dioxide",
        "Iron Oxides and Hydroxides",
        "Aluminium",
        "Silver",
        "Gold",
        "Pigment Rubine , Lithol Rubine BK",
        "Tannin",
        "Orcein, Orchil",
        "Sorbic Acid",
        "Soduim Sorbate",
        "Potassium Sorbate",
        "Calcium Sorbate",
        "Heptyl p-hydroxybenzoate",
        "Benzoic Acid",
        "Sodium Benzoate",
        "Potassium Benzoate",
        "Calcium Benzoate",
        "Ethyl 4-hydroxybenzoate",
        "Ethyl-p-hydroxybenzoate sodium salt",
        "Propyl 4-hydroxybenzoate",
        "Sodium Salt",
        "Methyl 4-hydroxybenzoate",
        "Methyl-p-hydroxybenzoate sodium salt",
        "Sulphur Dioxide",
        "Sodium Sulphite",
        "Sodium hydrogen sulphite",
        "Sodium Metabisulphite",
        "Potassium Metabisulphite",
        "Potassium sulfite",
        "Calcium Sulphite",
        "Calcium Hydrogen Sulphite",
        "Potassium hydrogen sulphite",
        "Biphenyl / Diphenyl",
        "2-Hydroxybiphenyl",
        "Phenylphenol sodium salt",
        "2-(Thiazol-4-yl)benzimidazole",
        "Nisin",
        "Pimaracin",
        "Formic acid",
        "Sodium formate",
        "Formic acid calcium salt",
        "Hexamine",
        "Formaldehyde",
        "Gum guaicum",
        "Dimethylcarbonate",
        "ethyl lauroyl arginate",
        "Potassium Nitrate",
        "Sodium Nitrite",
        "Sodium Nitrate",
        "Potassium nitrate",
        "Acetic Acid",
        "Potassium Acetate",
        "Sodium acetate",
        "Calcium Acetate",
        "Ammonium acetate",
        "Dehydroacetic acid",
        "Sodium dehydroacetate",
        "Lactic Acid",
        "Propionic acid",
        "Sodium Propionate",
        "Calcium Propionate",
        "Potassium propionate",
        "Boric acid",
        "Sodium tetraborate",
        "Carbon Dioxide",
        "Malic Acid",
        "Fumaric Acid",
        "Ascorbic acid (Vitamin C)",
        "Sodium-L-Ascorbate",
        "Calcium-L-Ascorbate",
        "Potassium ascorbate",
        "Ascorbyl Palmitate",
        "Ascorbyl stearate",
        "Tocopherol concentrate",
        "Alpha-tocopherol",
        "Synthetic Gamma-Tocopherol",
        "Delta Tocopherol",
        "Propyl Gallate",
        "Octyl gallate",
        "Dodecyl Gallate",
        "Thiodipropionic acid",
        "Guaiac Gum",
        "Erythorbic acid",
        "Sodium erythorbate",
        "Erythorbic acid",
        "Calcium erythorbate",
        "Butylhydroxinon",
        "Butylated Hydroxyanisole (BHA)",
        "Butylated Hydroxytoluene (BHT)",
        "Lecithin",
        "Anoxomer",
        "Ethoxyquin",
        "Sodium Lactate",
        "Potassium Lactate",
        "Calcium Lactate",
        "Ammonium lactate",
        "Magnesium lactate",
        "Citric Acid",
        "Sodium Citrates",
        "Potassium Citrates",
        "Calcium Citrates",
        "Tartaric Acid",
        "Sodium Tartrates",
        "Potassium Tartrates (Cream of Tartar)",
        "Potassium Sodium Tartrates",
        "Orthophosphoric Acid",
        "Sodium Phosphates",
        "Potassium Phosphates",
        "Calcium Phosphates",
        "Ammonium phosphate",
        "Monomagnesium phosphate",
        "Lecitin citrate",
        "Magnesium citrate",
        "Ammonium malate",
        "Sodium Malate",
        "Potassium Malate",
        "Calcium Malate",
        "Metataric Acid",
        "Calcium Tartrate",
        "Adipic Acid",
        "Sodium adipate",
        "Potassium adipate",
        "calcium adipates",
        "Aminium adipate",
        "Magnesium adipate",
        "Succinic Acid",
        "Sodium succinate",
        "Sodium fumarate",
        "Potassium fumarate",
        "Calcium fumarate",
        "Ammonium fumarate",
        "Magnesium fumarate",
        "Heptonolactone",
        "Nicotinic Acid",
        "Triammonium Citrate",
        "Ammonium Ferric Citrate",
        "Calcium glycerophosphate",
        "Isopropyl citrates",
        "Calcium disodium ethylenediamine",
        "Disodium ethylenediamine tetra-acetate",
        "Oxystearin",
        "Thiodipropionic acid",
        "Dilauryl thiodipropionate",
        "Distearyl thiodipropionate",
        "Phytic acid",
        "Rosemary extract",
        "Calcium lactobionate",
        "Alginic Acid",
        "Sodium Alginate",
        "Potassium Alginate",
        "Ammonium Alginate",
        "Calcium Alginate",
        "Propylene glycol alginate",
        "Agar",
        "Carrageenan",
        "Processed euchema seaweed",
        "Processed eucheuma seaweed (thickener) (stabiliser) (gelling agent)",
        "Bakers yeast glycan",
        "Arabinogalactan",
        "Locust Bean Gum",
        "Oat gum",
        "Guar Gum",
        "Tragacanth gum",
        "Gum Acacia (Gum Arabic)",
        "Xanthan Gum",
        "Karaya Gum",
        "Tara gum",
        "Gellan gum",
        "Gum ghatti",
        "Sorbitols",
        "Mannitol",
        "Glycerol",
        "Octenyl succinic acid (OSA) modified gum arabic",
        "Curdlan",
        "Konjac flour",
        "Soybean hemicellulose",
        "Cassia gum",
        "Gelatin",
        "Peptones",
        "Polyoxyethane (8) Stearate",
        "Polyoxyethane (40) Stearate",
        "Polyoxyethylene (20) sorbitan monolaurate",
        "Polyoxyethylene (20) sorbitan monooleate",
        "Polyoxyethylene (20) sorbitan monopalmitate",
        "Polyoxyethylene (20) sorbitan monostearate",
        "Polyoxyethylene sorbitan tristearate",
        "Pectins (i) pectin (ii) amidated pectin",
        "Pectins",
        "Amidated Pectin",
        "Superglycerinated hydrogenated rapeseed oil",
        "Ammonium salts of phosphatidic acid",
        "Brominated vegetable oils",
        "Sucrose acetate isobutyrate",
        "Glycerol esters of rosin",
        "Succistearin",
        "Diphosphates",
        "Triphosphates",
        "Polyphosphates",
        "Potassium Polyaspartate",
        "Cyclodextrin",
        "Gamma-cyclodextrin",
        "beta-Cyclodextrin",
        "Celluloses",
        "Methyl cellulose",
        "Ethyl cellulose",
        "Hydroxypropyl cellulose",
        "Hydroxypropyl methyl cellulose",
        "Methyl ethyl cellulose",
        "Sodium carboxymethyl cellulose",
        "Ethyl hydroxyethyl cellulose",
        "Cross-linked sodium carboxymethyl cellulose",
        "Sodium carboxymethyl cellulose",
        "Salts of fatty acids",
        "Salts of myristic, palmitic and stearic acids with ammonia, calcium, potassium and sodium",
        "Magnesium stearate",
        "Mono- and di- glycerides of fatty acids",
        "Esters of mono- and diglycerides",
        "Acetic and fatty acid esters of glycerol",
        "Lactic and fatty acid esters of glycerol",
        "Citric and fatty acid esters of glycerol",
        "Tartaric acid esters of mono- and di-glycerides of fatty acids",
        "Diacetyltartaric and fatty acid esters of glycerol",
        "Mixed esters (tartaric, acetic) of mono- and diglycerides",
        "Succinylated monoglycerides",
        "Sucrose esters of fatty acids",
        "Sucrose oligoesters",
        "Sucroglycerides",
        "Polyglycerol esters of fatty acids",
        "Polyglycerol esters of interesterified ricinoleic acid",
        "Propylene glycol esters of fatty acids",
        "Lactylated fatty acid esters of glycerol and propylene glycol",
        "Thermally oxidized soya bean oil interacted with monoand diglycerides of fatty acids",
        "Thermally oxidized soya bean oil interacted with mono- and diglycerides of fatty acids",
        "Dioctyl sodium sulfosuccinate",
        "Sodium lactylates",
        "Calcium lactylates",
        "Stearyl tartrate",
        "Stearyl citrate",
        "Sodium stearoyl fumarate",
        "Calcium stearoyl fumarate",
        "Sodium laurylsulfate",
        "Ethoxylated mono- and di-glycerides",
        "Methyl glucoside-coconut oil ester",
        "Propane-1,2-diol",
        "Sorbitan monostearate",
        "Sorbitan tristearate",
        "Sorbitan Monolaurate",
        "Sorbitan monooleate",
        "Sorbitan monopalmitate",
        "Sorbitan trioleate",
        "Polyoxypropylene-polyoxyethylene polymers",
        "Ãsteres parciales de poliglicerol de Ã¡cidos grasos policondensados del aceite de ricino",
        "Phytosterols Rich in Stigmasterol",
        "Sodium carbonates",
        "Potassium carbonates",
        "Ammonium carbonates",
        "Magnesium carbonates",
        "Ferrous carbonate",
        "Hydrochloric Acid",
        "Potassium chloride",
        "Calcium chloride",
        "Ammonium chloride",
        "Magnesium chloride",
        "Stannous chloride",
        "Sulfuric acid",
        "Sodium sulfates",
        "Potassium sulfates",
        "Calcium sulfate",
        "Ammonium sulfate",
        "Magnesium sulfate",
        "Cupric sulfate",
        "Aluminium sulfate",
        "Aluminium sodium sulfate",
        "Aluminium potassium sulfate",
        "Aluminium ammonium sulfate",
        "Sodium hydroxide",
        "Potassium hydroxide",
        "Calcium Hydroxide",
        "Ammonium hydroxide",
        "Magnesium hydroxide",
        "Calcium oxide",
        "Magnesium oxide",
        "Sodium ferrocyanide",
        "Potassium ferrocyanide",
        "Ferrous hexacyanomanganate",
        "Calcium ferrocyanide",
        "Sodium thiosulfate",
        "Dicalcium diphosphate",
        "Sodium aluminium phosphates",
        "Bone phosphate",
        "Calcium sodium polyphosphate",
        "Calcium Polyphosphates",
        "Ammonium Polyphosphates",
        "Magnesium pyrophosphate",
        "Sodium silicates",
        "Silicon dioxide",
        "Calcium silicate",
        "Magnesium silicates",
        "(i) Magnesium silicate (ii) Magnesium trisilicate",
        "Talc",
        "Sodium aluminosilicate",
        "Potassium aluminium silicate",
        "Aluminium Calcium Silicate",
        "Zinc silicate",
        "Bentonite",
        "Aluminium silicate",
        "Potassium silicate",
        "Vermiculite",
        "Sepiolite",
        "Sepiolitic clay",
        "Lignosulfonates",
        "Natrolite-phonolite",
        "Fatty acids",
        "Ammonium stearate",
        "Magnesium stearate",
        "Aluminium stearate",
        "Gluconic acid",
        "Glucono delta-lactone",
        "Sodium gluconate",
        "Potassium Gluconate",
        "Calcium Gluconate",
        "Ferrous gluconate",
        "Magnesium gluconate",
        "Ferrous lactate",
        "Hexylresorcinol",
        "Synthetic calcium aluminates",
        "Perlite",
        "Glutamic acid",
        "Monosodium L-glutamate",
        "Monopotassium L-glutamate",
        "Calcium di-L-glutamate",
        "Monoammonium L-glutamate",
        "Magnesium di-L-glutamate",
        "Guanylic acid",
        "Disodium guanylate, sodium guanylate",
        "Dipotassium guanylate",
        "Calcium guanylate",
        "Inosinic acid",
        "Disodium 5â-inosinate",
        "Potassium 5â-inosinate",
        "Calcium inosinate",
        "Calcium 5â-ribonucleotides",
        "Sodium ribonucleotides",
        "Maltol",
        "Ethyl Maltol",
        "Sodium L-aspartate",
        "Alanine",
        "Glycine and its sodium salt",
        "Leucine",
        "Lysin hydrochloride",
        "Zinc acetate",
        "Tetracyclines",
        "Chlortetracycline",
        "Oxytetracycline",
        "Oleandomycin",
        "Penicillin G potassium",
        "Penicillin G sodium",
        "Penicillin G procaine",
        "Penicillin G benzathine",
        "Spiramycins",
        "Virginiamycins",
        "Flavomycin",
        "Tylosin",
        "Monensin A",
        "Avoparcin",
        "Salinomycin",
        "Avilamycin",
        "Dimethyl-polysiloxane",
        "Polydimethylsiloxane",
        "Methylphenylpolysiloxane",
        "Beeswax",
        "Candelilla wax",
        "Carnauba wax",
        "Shellac",
        "Paraffins",
        "Mineral oil",
        "Petroleum jelly",
        "Petroleum wax",
        "Mineral oil, high viscosity",
        "Mineral oil, medium and low viscosity",
        "Mineral oil, medium and low viscosity, class II",
        "Mineral oil, medium and low viscosity, class III",
        "Benzoin gum",
        "hydrogenated polydecene",
        "Rice bran wax",
        "Spermaceti wax",
        "Wax esters",
        "Methyl esters of fatty acids",
        "Montan wax",
        "Lanolin",
        "Oxidized polyethylene wax",
        "Pentaerithrytol esters of colophane",
        "Calcium iodate",
        "Potassium iodate",
        "Oxides of nitrogen",
        "Nitrosyl chloride",
        "Cysteine",
        "Cystine (L-) and its hydrochlorides â sodium and potassium salts",
        "Potassium persulfate",
        "Ammonium persulfate",
        "Potassium bromate",
        "Potassium bromate",
        "Calcium bromate",
        "Chlorine",
        "Chlorine dioxide",
        "Azodicarbonamide",
        "Urea (Carbamide)",
        "Benzoyl peroxide",
        "Acetone peroxide",
        "Calcium peroxide",
        "Argon",
        "Helium",
        "Dichlorodifluormethane",
        "Nitrogen",
        "Nitrous oxide",
        "Butane",
        "Isobutane",
        "Propane",
        "Chloropentafluorethane",
        "Octafluorcyclobutane",
        "Oxygen",
        "Hydrogen",
        "Acesulfame potassium",
        "Aspartame",
        "Cyclamates",
        "Isomalt",
        "Saccharins",
        "Sucralose",
        "Alitame",
        "Thaumatin",
        "Glycyrrhizin",
        "Neohesperidine dihydrochalcone",
        "Steviol glycosides",
        "Neotame",
        "Aspartame-acesulfame",
        "Tagatose",
        "Polyglycitol syrup",
        "Maltitols",
        "Lactitol",
        "Xylitol",
        "Erythritol",
        "Advantame",
        "Quillaia extracts",
    ]
}
