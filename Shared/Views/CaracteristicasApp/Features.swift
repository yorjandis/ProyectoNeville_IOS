//
//  Features.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 9/12/25.
//



import SwiftUI

//Ventana de Novedades de la App
struct Features: View {
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack{

                ScrollView {
                    VStack(alignment: .leading, spacing: 20){
                        Text("""
                        Bienvenido a una nueva Versión de La Ley
                        Esta versión: \(AppCons.appVersion!), cuenta con las siguientes Características:
                        """
                        )
                        VStack(alignment: .leading, spacing: 20){
                            //Numeros de Conferencias:
                            Text("☘️ conferencias y  libros: 472")
                            //Compendio de Frases:
                            Text("☘️ Compendio de Frases: 439. Se pueden crear nuevas frases personales. Las Frases incorporadas se han extraido textualmente de toda la obra de neville. Podemos crear Frases desde Siri: [<Oye siri> en La Ley crea una frase]. Podemos compartirlas, copiarlas a Notas, marcarse como favoritas, importarlas desde QR, pasarlas al Lienzo y editar solo las frases personales. Funciones IA sobre Frases: Interpretar, aplicación práctica y chatIA. Cada Frase tiene asociada un campo de nota propio, para hacer anotaciones sobre dicha frase. Las Frases se almacenan localmente y en la nube de iCloud con nuestro Apple ID; no se eliminan aunque desintalemos la aplicación")
                            //Notas:
                            Text("☘️ Notas Personales ilimitadas. Podemos crear Notas desde Siri: [<Oye Siri> en La Ley crea una nota]. Las notas pueden ser compartidas, exportadas a QR, al lienzo y marcarse como favoritas. Funciones de IA sobre Notas: Interpretar, Aplicación Práctica y ChatIA. El acceso a las Notas puede ser protegido por autenticación biométrica/contraseña, en Ajustes de la App. Las Notas se almacenan localmente y en la nube de iCloud con nuestro Apple ID; no se eliminan aunque desintalemos la aplicación")
                            
                            //Diario.
                            Text("☘️ Diario Personal para registrar nuestras experiencias y hechos de cada día. Muy útil para llevar un registro de nuestras asunciones, deseos y experiencias con estas enseñanzas y nuestra vida. Cada entrada del Diario tiene una fecha de creación, que nunca cambia, y una fecha de modificación que puede cambiar si modificamos la entrada en el futuro. El acceso al Diario esta protegido por autentifación biométrica; y una clave personal, cifrada y almacenada en el llavero del sistema, que puede ser utiliza si el dispositivo no tiene acceso biométrico. El Diario cuenta con potentes funciones de búsqueda y filtrado para encontrar una entrada ya sea por su título o contenido. Cuanta con un práctico calendario donde podemos ver las entradas que se han creado en el mes y navegar por las entradas creadas. Las entradas del Diario se almacenan localmente y en la nube de iCloud con nuestro Apple ID; no se eliminan aunque desintalemos la aplicación")
                            
                            //Evaluación:
                            Text("☘️ Evaluación: Un juego de elegir la respuesta correcta/incorrecta. Nos ayuda a consolidar y repasar lo aprendido en estas enseñansas. Las preguntas pueden tener doble sentido y ser sutiles para hacer más desafiente su interpretación.")
                            
                            //Funciones de QR
                            Text("☘️ El lector y generador de QR integrado nos permite importar información como Notas, Frases, etc desde y hacia la aplicación. Se ha creado un formato propio de importación/exportación de Frase y Notas con el cual se puede compartir con amigos y la comunidad.")
                            
                            //Funciones de Inteligencia Artificial (IA):
                            Text("☘️ Inteliegncia Artifical (IA) <Premium>. Las funciones propias de IA son: Interpretación, resumen, generación de concejos prácticos y chat sobre temas de las enseñanzas. La IA funciona de manera local y no requiere conexión a internet. Preserva la información personal y no la expone a terceros. Se requiere aceptar un descargo de responsabilidad para poder hacer uso de la IA. La IA ha sido cuidadosamente instruida para responder solo en el contexto de las enseñansas de neville")
                            
                            
                            //Lienzo
                            Text("☘️ Lienzo <Premiun>: Una forma creativa de diseñar tus propios fondos con imágines, colores y texto. Ideal para compartir frases y pensamientos en redes sociales y con amigos")
                            
                            //Atajos
                            Text("☘️ Atajos & Comandos de Siri <Premiun>: Se han creado varios Atajos, visible en la App Atajos, para realizar las siguientes acciones:")
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
                        }
                        
                        VStack{
                            Button("Cerrar"){
                                dismiss()
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundStyle(.black)
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 10)
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
