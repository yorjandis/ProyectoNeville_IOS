//
//  watchModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 15/2/25.
//

import SwiftUI

@MainActor
final class watchModel: ObservableObject {
    
    @Published var listfrases : [String] = []

    
    ///Obtiene la lista de frases del fichero txt in-built(De momento no muestra las frases personales, deben ser solicitadas desde iOS):
    /// - Returns: Devuelve un  arreglo de cadenas con las frases cargadas del txt en Staff
    func getfrasesArrayFromTxtFile(){
        self.listfrases.removeAll()
        //Extrayendo las frases inbuilt, almacenadas dentro del bundle de la App
        self.listfrases = UtilFuncs.FileReadToArray(AppCons.FileListFrases)
    }
    
    
    
    
    
}
