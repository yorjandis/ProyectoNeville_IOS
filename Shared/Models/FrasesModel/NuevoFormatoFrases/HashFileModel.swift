//
//  HashFileModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 17/1/26.
//

//Este fichero se encarga de calcular el hash de los ficheros TXT de Frases y determinar si alguno de ellos ha cambiado.
/*
 1.Se calcula un hash global de la suma de hash de cada fichero TXT
 2.Este valor se almacena en UserDefault.
 3.En cada actualización de la App (o en la primera instalación) se recalcula el hash y se compara con el alamcenado en UserDefault:
    si no coinciden: se ejecuta el importador
    si los hash son iguales: no se ejecuta el importador
 
 */


import Foundation
import CryptoKit


struct HashFileModel {
    
    static let UD_HashFrasesTXT = "UD_HashFrasesTXT" //Clave en UserDefault para almacenar el flagGlobal
    
    //Calcula el hash de una cadena:
    /*
     ✔️ Estable
     ✔️ Rápido
     ✔️ Ideal para detección de cambios
     */
   private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    //Devuelve el hash de un fichero TXT
    //📌 El trim evita falsos positivos por saltos de línea accidentales.
    private func hashDeFicheroTXT(_ filename: String) -> String {
        let contenido = UtilFuncs.FileRead(filename)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        
        return sha256(contenido)
    }
    
    
    //Hash Conbinado, o global:
    /*
     ✔️ Si cambia un solo fichero → cambia el hash global
     ✔️ Puedes añadir más TXT sin romper nada
     */
    private func hashGlobalFrasesTXT(_ filenames: [String]) -> String {
        let hashes = filenames
            .sorted()                 // importante para estabilidad (siempre se ordenan los ficheros txt)
            .map {hashDeFicheroTXT($0) }
            .joined(separator: "|")   // separador estable
        
        return sha256(hashes)
    }
    
    
    //Verifica el hash Global y determina si ha cambiado, con respecto al almacenado en UserDefault
    //Si devuelve nil es que no ha habido cambios en los ficheros TXT
    @MainActor
    func VerificarHashGlobal(NameArchivosTXT : [String])->String?{
        
       
        
        let userDefaultsGroup = UserDefaults(suiteName: "group.com.ypg.nev.group")

            let hashActual = hashGlobalFrasesTXT(NameArchivosTXT) //Calcula Hash Global
            let hashGuardado = userDefaultsGroup?.string(forKey: HashFileModel.UD_HashFrasesTXT) //extrae el valor del hash global almacenado

        
        
            //Comparando...
            if hashActual == hashGuardado {
                //TXT sin cambios. No se ejecuta el importador
                return nil
            }else{
                //TXT con cambios. Se ejecuta el importador
                return hashActual
            }
    }
    
    
    //Para debug: Resetar el hashGlobal para forzar a que importador se ejecute
    func ResetearHashGlobal(){
        let userDefaultsGroup = UserDefaults(suiteName: "group.com.ypg.nev.group")
        userDefaultsGroup?.removeObject(forKey: HashFileModel.UD_HashFrasesTXT)
    }
}



