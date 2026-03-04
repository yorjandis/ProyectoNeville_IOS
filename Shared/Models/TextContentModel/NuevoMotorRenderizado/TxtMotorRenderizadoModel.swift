//
//  TxtMotorRenderizadoModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/2/26.
//

/*
 
 */

import SwiftUI



//Bloque básico de contenido
struct ContentBlock: Identifiable {
    let id: UUID
    let content: BlockType
    
    init(id: UUID = UUID(), content: BlockType) {
        self.id = id
        self.content = content
    }
}

//Tipos de elementos de contenido
enum BlockType {
    case text(String)
    case markdown(String)
    case attributed(AttributedString)
    case imageLocal(name: String, size : CGFloat)
    case imageRemote(url: URL, size : CGFloat)
    case link(title: String, url: URL)
    case bulletList([String])
    case quote(String)
    case code(String)
    case divider
    case bibliography(title: String?, entries: [BibliographyEntry]) //Para mostrar referencias bibliográficas al contenido
    case relacionado(title: String?, fileNames: [RelatedItem])
}

//Divide los boques de texto largos en un arreglo de parráfos
extension String {
    
    func splitIntoParagraphs() -> [String] {
        self
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}


//Toma el arreglo de bloques para mostrar y procesa los de tipo .text para convertirlos en varios ContentBlock según la cantidad de párrafos.
extension Array where Element == ContentBlock {
    
    func expandedTextBlocks() -> [ContentBlock] {
        
        self.flatMap { block -> [ContentBlock] in
            
            switch block.content {
                
            case .text(let string):
                return string
                    .splitIntoParagraphs()
                    .map { ContentBlock(content: .text($0)) }
                
            default:
                return [block]
            }
        }
    }
}

//Para Items relacionados
struct RelatedItem: Identifiable {
    let id = UUID()
    let fileName: String      // Nombre real del archivo en el bundle
    let displayName: String   // Nombre legible para mostrar
}
