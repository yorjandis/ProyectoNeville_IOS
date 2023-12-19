//
//  Pruebas.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 7/12/23.
//

import Foundation
import CoreData
import SwiftUI

protocol Personas{}
protocol Mascotas{}


struct Persona : ~Copyable{
    let name : String
}



func primera(){
    
    let p1 = Persona(name: "juan")
    consumir(a: p1)
    print(p1.name)
}





func consumir(a : borrowing Persona){
   print(a.name)
  
}












    




