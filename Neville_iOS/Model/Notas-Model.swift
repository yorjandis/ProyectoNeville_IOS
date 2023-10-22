//
//  Notas-Model.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 20/10/23.
//
//Operaciones con  notas

import Foundation



struct NotasModel{
    
    ///Adiciona una nueva nota a la BD
    /// - Returns `true` si OK, `false` si error
    static func AddNota(title: String, nota: String)->Bool{
        let title = title.trimmingCharacters(in: .whitespaces)
        let nota = nota.trimmingCharacters(in: .whitespaces)
        
        if (nota.isEmpty || title.isEmpty) {return false}
        
        if  manageNotas().addNote(nota: nota, title: title).0 {
       
            return true
        }else{
            return false
        }
    }
    
    ///Actualiza el contenido de una nota
    /// - Returns `true` si OK, `false` si error
    //Guardar un valor
    static func Update(id: String, title: String, nota: String)->Bool{
        let result = manageNotas().updateNota(NotaID: id, newTitle: title, newNota: nota)
        if result {
            return true
        }else{
           return false
        }
    }
}


