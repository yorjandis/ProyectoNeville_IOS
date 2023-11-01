//
//  Notas-Model.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 20/10/23.
//
//Operaciones con  notas

import Foundation



struct NotasModel{
    
    private  let context = CoreDataController.dC.context
    
    ///Adiciona una nueva nota a la BD
    /// - Returns `true` si OK, `false` si error
     func AddNota(title: String, nota: String)->Bool{
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
     func Update(id: String, title: String, nota: String)->Bool{
        let result = manageNotas().updateNota(NotaID: id, newTitle: title, newNota: nota)
        if result {
            return true
        }else{
           return false
        }
    }
    
    ///Elimina una nota de la BD
    /// - Returns - return true if ok, false otherwise
    func deleteNota(nota : Notas)->Bool{
        var result = false
        context.delete(nota)
        do {
            if context.hasChanges {
                try context.save()
                result = true
            }
        } catch {
            result = false
            print(error.localizedDescription)
        }
        return result
    }
    
    
}


