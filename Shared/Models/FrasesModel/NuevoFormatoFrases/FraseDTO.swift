//
//  DTO.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 14/1/26.
//

//Se agregarán los nuevos campos a los bloques de las Frases

import SwiftUI

//Primero definimos una estructura que represente una frase ya parseada, independiente de Core Data.
struct FraseDTO {
    let id:         String      //Id fijo
    let autor:      String      //Nombre del Autor de la Frase
    let nota:       String      //La nota asociada a la frase
    let fuente:     String      //La fuente de donde es tomada la frase (conferencia, libro, etc)
    let contexto:   [String]    //los temas generales sobre los que se enmarca la frase (es para agrupar varias frases sobre una idea o tema general)
    let texto:      String      //El texto de la Frase
    let relacionadas: [String]  //conjunto de ids de frases que se relacionan semánticamente con esta frase (por lo general, las frases que tienen el mismo contexto se relacionan entre sí )
}

//Formato esperado en el Txt de Frases
/*
 id=nev_001
 autor=nev
 nota=Esto es una nota de ejemplo
 fuente=Tomado de la conferencia: ""
 cotexto="Creación de la Realidad,Poder creativo de Dios"
 texto=En presencia de la dignidad los principios no se negocian
 relacionadas=nev_002,nev_005

 id=nev_002
 autor=nev
 nota=Esto es una nota de ejemplo
 fuente=Tomado de la conferencia: ""
 cotexto="Creación de la Realidad,Poder creativo de Dios"
 texto=En presencia de la dignidad los principios no se negocian
 relacionadas=nev_002,nev_005
 */


/*
 Ventajas de este enfoque
 ✔ Migración automática sin tocar Core Data
 ✔ IDs estables y legibles
 ✔ Parser tolerante a errores
 ✔ Formato editable a mano
 ✔ Escalable (añadir idioma, categoría, época, etc.)
 */
