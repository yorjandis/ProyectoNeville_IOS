//
//  BibliografiaModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 25/2/26.
//

import SwiftUI

struct BibliographyEntry: Identifiable {
    let id = UUID()
    let text: String
    let url: URL?
}

//Parsea un archivo de bibli_ de bibliografia
func parseBibliographyFile(_ fileName: String) -> [BibliographyEntry] {
    
    let rawText =  UtilFuncs.FileRead(fileName, omittingFirstLines: 1)
    
    let rawEntries = rawText
        .components(separatedBy: "\n\n")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    
    return rawEntries.map { entry in
        
        let lines = entry
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // Buscar línea que empieza por "enlace:"
        let linkLine = lines.first(where: {
            $0.lowercased().hasPrefix("enlace:")
        })
        
        var extractedURL: URL? = nil
        
        if let linkLine {
            let urlString = linkLine
                .replacingOccurrences(of: "enlace:", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            extractedURL = URL(string: urlString)
        }
        
        return BibliographyEntry(
            text: lines.joined(separator: "\n"), // 🔥 ya no eliminamos nada
            url: extractedURL
        )
    }
}

/*
 Ejemplo de llamada:
 let entries = parseBibliographyFile("bibli_01")
 ContentBlock(content: .bibliography(title: "Fundamentos", entries: entries))
 
 */
