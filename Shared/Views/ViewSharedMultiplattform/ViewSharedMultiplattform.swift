//
//  ViewSharedMultiplattform.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/12/25.
//


//Fichero donde estará todos los helper de UI compartidos para lo target habilitados: iOS, macOS, watchOS, ipadOS, etc


import SwiftUI

//Representa un item que almacena el texto en el portapapales de iOS y macOS. Utilizado para lanzar sheet(item : TextoCopiadoAlPortapapeles ){}
//el tipo de dato para el parámetro item del sheet debe ser identifiable, por tanto debe tener una estructura semejante a esta.
struct TextoCopiadoAlPortapapeles : Identifiable {
    var id: UUID = UUID()
    var texto : String
}
