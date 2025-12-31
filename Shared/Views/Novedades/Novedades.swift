//
//  Novedades.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 2/12/25.
//

import SwiftUI

//Ventana de Novedades de la App
struct Novedades: View {
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack{

                ScrollView {
                    VStack(alignment: .leading, spacing: 20){
                        Text("""
                        Bienvenido a una nueva Versión de La Ley
                        Esta versión: \(AppCons.appVersion!), cuenta con las siguientes Novedades:
                        """
                        )
                        VStack(alignment: .leading, spacing: 20){
                            //Lienzo
                            Text("☘️ Lienzo: Una forma creativa de diseñar tus propios fondos con imágines, colores y texto. Ideal para compartir frases y pensamientos en redes sociales y con amigos")
                            
                            //Atajos
                            Text("☘️ Atajos & Comandos de Siri: Se han creado varios Atajos, visible en la App Atajos, para realizar las siguientes acciones:")
                            VStack(alignment: .leading, spacing: 5){
                                Text("🔸Abrir el Diario:").foregroundStyle(.orange)
                                Text("Abre directamente la ventana del Diario. \nComando de Siri:")
                                            (
                                                Text("<Oye Siri> en la ley abre mi diario")
                                                    .foregroundColor(.purple)
                                                    .italic()
                                            )
                                Text("\n🔸Crear entrada del Diario:").foregroundStyle(.orange)
                                Text("Crea una entrada de diario sin abrir la aplicación, de manera silenciosa. \nComando de Siri:")
                                (
                                    Text("<Oye Siri> en la la ley crea una entrada")
                                        .foregroundColor(.purple)
                                        .italic()
                                    +
                                    Text("\nSiri te pedirá la contraseña, un título y un contenidp para crear la entrada del Diario. Si la contraseña es confusa, conviene deletrearla de manera clara y pausada")
                            )
                                Text("\n🔸Abrir las notas:").foregroundStyle(.orange)
                                Text("Abre la ventana de la lista de Notas en la Aplicación. \nComando de Siri:")
                                (
                                    Text("<Oye Siri> en la ley abre mis notas")
                                        .foregroundColor(.purple)
                                        .italic()
                                    
                                )
                                
                                
                                
                                Text("\n🔸Crear una nota").foregroundStyle(.orange)
                                Text("Crea una nota de manera silenciosa, sin abrir la aplicación. \nComando de Siri:")
                                    (
                                        Text("<Oye Siri> en la ley crea una nota")
                                            .foregroundColor(.purple)
                                            .italic()
                                        +
                                        Text("\nSiri le pedirá que dicte un título y la nota")
                                    )
                                Text("\n🔸Crear una frase").foregroundStyle(.orange)
                                Text("Crea una frase personal de manera silenciosa, sin abrir la aplicación. \nComando de Siri:")
                                (
                                    Text("<Oye Siri> en la ley crea una frase")
                                        .foregroundColor(.purple)
                                        .italic()
                                    +
                                    Text("\nSiri pedirá que dicte la nueva frase")
                                )
                                Text("\n🔸Abrir una Conferencia al azar").foregroundStyle(.orange)
                                Text("Abre la aplicación y muestra una conferencia al azar")
                                (
                                    Text("<Oye Siri> en la ley abre conferencia")
                                        .foregroundColor(.purple)
                                        .italic()
                                )
                                
                            }
                            //Correcciones y Mejoras en Frases
                            Text("☘️ Varias correcciones y mejoras en Frases. Ahora es posible editar las frases personales. También se ha añadido, en el menú contextual, las opciones de compartir la frase y almacenarlas en Notas")
                            Text("☘️ Nuevo en Diario: Se ha añadido una opción en Ajustes para mantener el Diario desbloqueado una vez se ha accedido al mismo. Esto evita tener que pasar la validación en cada acceso al Diario")
                            Text("☘️ Se ha modificado las políticas de privacidad para introducir como se gestiona la privacidad en las nuevas funciones de Inteligencia Artificial")
                            Text("☘️ Varias mejoras y correcciones en Notas")
                            Text("☘️ Nuevo: Ahora se muestra las cinco conferencias vistas recientemente")
                            Text("☘️ Varias mejoras y correcciones en Reflexiones. Ahora es posible editar las reflexiones")
                            Text("☘️ Se ha introducido en menú de funciones para el texto copiado en conferencias, frases, notas, respuestas de IA, etc. Esté menú aparece automáticamente una vez hayamos seleccionado un texto y copiado al portapapeles. Algunas de las funciones son: copiar en Notas, copiar en el Lienzo, copiar en la ventana de chatIA, etc")
                            Text("☘️ Nuevo: Recordatorios. Ahora podemos programar avisos para nunca olvidar las tareas esenciales: meditar, revisión del día, dar gracias, afirmaciones, etc")
                            Text("☘️ macOS: Se ha mejorado la experiencia en el manejo y visualización de las ventanas flotantes")
                            Text("☘️ Se ha mejorado la función de lector/generador de QR Code. Ahora puede manejar el Formato de Importación de Notas para importar notas automáticamente")
                            Text("☘️ IA: Se ha revisado y afinado los ajustes que controlan las respuestas de la IA. Ahora es más natural y fluida. Además, se ha enriquecido el conocimiento base con más información sobre las enseñanzas de neville")
                            Text("☘️ IA: Ahora podemos enviar el texto en el ChatIA con un enter: macOS")
                            Text("☘️ IA: Se ha añadido una opción en Ajustes para controlar el papel interpretado por la Inteligencia Artificial: Personal o Impersonal. Si es Personal, la IA actuará como si fuera neville. Si no se siente a gusto puede cambiar al tono Impersonal")
                            Text("☘️ Corregido: No se aplicaba el tamaño de letra a las listas de elementos. Ahora sí")
                            Text("☘️ Se actualizó el email, en Ajustes, para enviar comentarios y sugerencias a través de la app")
                            Text("Estas Novedades estarán en Ajustes, en el área de información")
                                .padding(.vertical, 10)
                        }
                        
                        VStack{
                            Button("Cerrar"){
                                dismiss()
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundStyle(.black)
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                    
                    
                }
            .font(.system(size: 18))
            .padding(.horizontal, 10)
            #if os(macOS)
            .frame(width: 660, height: 400)
            #endif
        }
        .background{
            LinearGradient(colors: [ .gray.opacity(0.4),.blue.opacity(0.2) ], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
           
      
        
    }
    
}


#Preview {
    Novedades()
}
