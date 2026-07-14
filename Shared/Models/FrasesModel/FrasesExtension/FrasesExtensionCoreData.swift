//
//  FrasesExtensionCoreData.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 2/2/26.
//

import Foundation
import CoreData

//Variables computadas:
extension Frases{
    //Es personal la frase
    var isPersonal: Bool {
        noinbuilt
    }
    
    //Frase Tiene Nota
    var tieneNota: Bool {
        !(nota?.isEmpty ?? true)
    }
    
    //Normaliza el texto de la frase
    var textoNormalizado: String {
        frase?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
    }

    var translationsArray: [PhraseTranslation] {
        Array(translations as? Set<PhraseTranslation> ?? [])
    }

    private var preferredTranslation: PhraseTranslation? {
        for language in AppLanguage.current.fallbackChain {
            if let translation = translationsArray.first(where: {
                $0.localeIdentifier == language.rawValue
            }) {
                return translation
            }
        }
        return nil
    }

    /// Texto editorial localizado. Las frases personales siempre conservan el texto del usuario.
    var localizedText: String {
        guard !isPersonal else { return frase ?? "" }
        return preferredTranslation?.text ?? frase ?? ""
    }

    var localizedSource: String {
        guard !isPersonal else { return fuente ?? "" }
        return preferredTranslation?.source ?? fuente ?? ""
    }

    /// Nota incluida por el editor del contenido. No es la nota personal almacenada en `nota`.
    var localizedEditorialNote: String {
        guard !isPersonal else { return "" }
        return preferredTranslation?.editorialNote ?? ""
    }

    @discardableResult
    func upsertTranslation(
        locale: AppLanguage,
        text: String,
        source: String,
        editorialNote: String,
        context: NSManagedObjectContext
    ) -> Bool {
        let translation: PhraseTranslation
        if let existing = translationsArray.first(where: { $0.localeIdentifier == locale.rawValue }) {
            translation = existing
        } else {
            translation = PhraseTranslation(context: context)
            translation.id = UUID()
            translation.localeIdentifier = locale.rawValue
            translation.phraseID = id
            translation.phrase = self
        }

        let changed = translation.text != text
            || translation.source != source
            || translation.editorialNote != editorialNote
        translation.text = text
        translation.source = source
        translation.editorialNote = editorialNote
        translation.phraseID = id
        return changed
    }
    
    //Devuelve el nombre del Autor completo
    var getNameAutor : String {
        switch self.autor {
        case "nev": return "Neville Goddard (Conferencista,Autor, Místico y Pensador)"
        case "jd": return "Dr. Joe Dispenza (Conferencista, Autor, especialidad: Neurociencia y conexión mente-cuerpo)"
        case "bruceL": return "Dr. Bruce H. Lipton (Biólogo Molecular, Autor, Conferecista)"
        case "gregg": return "Greegg Braden (Autor, Conferencista, Geólogo, Antiguas Culturas)"
        default: return self.autor ?? ""
        }
    }
    
    
}


    


//Actualizar una frase Personal:
extension Frases {
    func actualizarFrasePersonal(
            texto: String,
            nota: String,
            autor: String,
            isFav: Bool,
            context: NSManagedObjectContext
        ) throws {
            guard isPersonal else { return }

            self.frase = texto
            self.nota = nota
            self.autor = autor
            self.isfav = isFav

            if context.hasChanges {
                try context.save()
            }
        }
    /*
     en el FrasesModel:
     try frase.actualizar(...)
     */
}

//Resolver Duplicados:
extension Frases {
    //Resuelve las frases duplicadas y devuelve el número de frases duplicadas que se han procesado
    static func resolverDuplicados(
            en context: NSManagedObjectContext
        ) throws -> Int {

            let request: NSFetchRequest<Frases> = fetchRequest()
            let frases = try context.fetch(request)

            let grupos = Dictionary(grouping: frases) {
                $0.textoNormalizado
            }

            var eliminadas = 0

            for grupo in grupos.values where grupo.count > 1 {
                let conservar = grupo.sorted {
                    $0.isPersonal && !$1.isPersonal
                }.first!

                grupo.filter { $0 != conservar }.forEach {
                    context.delete($0)
                    eliminadas += 1
                }
            }

            if context.hasChanges {
                try context.save()
            }

            return eliminadas
        }
    /*
     en FrasesModel:
     let eliminadas = try Frases.resolverDuplicados(en: context)
     */
}


//Reutilizar Queries Fetch:
enum FrasesQuery {
    case todas
    case favoritas
    case personales
    case conNotas
    case porAutor(String)
    case buscarTexto(String)
    case buscarEnNotas(String)
}
extension Frases {

    //Devuelve el listado de frases de acuerdo con criterios de filtro
    //Nota: en FrasesModel hay 20 funciones con fetch repetidos.
    static func fetch(_ query: FrasesQuery,context: NSManagedObjectContext) throws -> [Frases] {

        let request: NSFetchRequest<Frases> = fetchRequest()

        switch query {
        case .buscarEnNotas(let text):
            request.predicate = NSPredicate(format: "nota CONTAINS[cd] %@", text)
        case .favoritas:
            request.predicate = NSPredicate(format: "isfav == YES")

        case .personales:
            request.predicate = NSPredicate(format: "noinbuilt == YES")

        case .conNotas:
            request.predicate = NSPredicate(format: "nota != nil AND nota != ''")

        case .buscarTexto(let text):
            _ = text // La traducción activa se filtra en memoria después del fetch.

        case .porAutor(let autor):
            request.predicate = NSPredicate(format: "autor == %@", autor)
            
        case .todas:
            break
        }

        let result = try context.fetch(request)
        if case .buscarTexto(let text) = query {
            return result.filter { $0.localizedText.localizedCaseInsensitiveContains(text) }
        }
        return result
    }
}

//Devuelve una entidad Frase dado su texto:
extension Frases {
    static func getFraseByText(fraseTexto: String, context: NSManagedObjectContext) throws -> Frases? {
        let request: NSFetchRequest<Frases> = Frases.fetchRequest()
        request.predicate = NSPredicate(format: "frase == %@", fraseTexto)
        if let canonical = try context.fetch(request).first {
            return canonical
        }

        let allRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        return try context.fetch(allRequest).first { $0.localizedText == fraseTexto }
    }
}
