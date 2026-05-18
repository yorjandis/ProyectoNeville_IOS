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
                            Text("☘️ Compendio de Frases: 439. Se pueden crear nuevas frases personales. Las Frases incorporadas se han extraido textualmente de toda la obra de neville. ")
                            
                            //Autores:
                            Text("☘️ Se ha incorporado las enseñanzas de varios autores: Joe Dispenza, Bruce Lipton y Gregg Braden. Los aportes en sus respectivos campos de especialziación apoyan las enseñanzas de Neville y nos empoderan para llevar una vida más saludable y en armonía.")
                            
                            //Enciclopedia:
                            Text("☘️ Enciclopedia de conocimientos. Se ha creado un espacio de aprendisaje y nuevo conocimiento relacionado con las enseñanzas.")
                            
                            //Evidencia científica:
                            Text("☘️ Evidencia Científica: Un resumen, debidamente acotado y en crecimiento, sobre las investigaciones y estudios científicos que apoyan estas enseñanzas")
                            
                            //Notas:
                            Text("☘️ Notas Personales ilimitadas. Podemos crear Notas desde Siri: [<Oye Siri> en La Ley crea una nota]. Las notas pueden ser compartidas, exportadas a QR, al lienzo y marcarse como favoritas. Admiten funciones IA: Interpretar, Aplicación Práctica y ChatIA.")
                            
                            //Diario:
                            Text("☘️ Diario Personal para registrar nuestras experiencias y hechos de cada día. Muy útil para llevar un registro de nuestras asunciones, deseos y experiencias con estas enseñanzas y nuestra vida.")
                            
                            //Metas:
                            Text("☘️ Metas permite crear objetivos y seguir su progreso. Cada objetivo es creado con la información necesaria para que pueda lograrse de manera óptima.")
                            
                            //Recordatorios:
                            Text("☘️ Recordatorios: Los recordatorios son una forma de programar avisos para no olvidarse de nada. Además resultan útiles para sesiones de meditación, entrenamiento, etc")
                            
                            //Ritual Matutino:
                            Text("☘️ Ritual matutino: Una forma de organizar intencionalmente tu día y mentaner el foco en el presente.")
                            
                            //Espacio Calma:
                            Text("☘️ Espacio Calma: Una experiencia inmersiva para relajarte y desconectarte. Ayuda a disminuir el estress y la ansiedad.")
                            
                            //Lector de Etiquetas:
                            Text("☘️ Lector de Etiquetas: Ofrece información sobre alimentos y concejos de uso, leyendo su código de barras.")
                            
                            //Coherencia Cardio cerebral:
                            Text("☘️ Coherencia Cardio-Cerebral: Asistente de guía para entrar en estado de coherencia entre corazón y cerebro.")
                            
                            //Agenda:
                            Text("☘️ Agenda: Organiza tus tareas, eventos y compromisos en el tiempo para que liberes tu memoria, priorices lo importante y uses tu tiempo de manera más óptima e intencional.")
                            
                            //Evaluación:
                            Text("☘️ Evaluación: Un juego de elegir la respuesta correcta/incorrecta. Nos ayuda a consolidar y repasar lo aprendido en estas enseñansas. Las preguntas pueden tener doble sentido y ser sutiles para hacer más desafiente su interpretación.")
                            
                            //Funciones de QR
                            Text("☘️ El lector y generador de QR integrado nos permite importar información como Notas, Frases, etc desde y hacia la aplicación. Se ha creado un formato propio de importación/exportación de Frase y Notas con el cual se puede compartir con amigos y la comunidad.")
                            
                            //Funciones de Inteligencia Artificial (IA):
                            Text("☘️ Inteliegncia Artifical (IA) <Versión Extendida>. Las funciones propias de IA son: Interpretación, resumen, generación de concejos prácticos y chat sobre temas de las enseñanzas. La IA funciona de manera local y no requiere conexión a internet.La IA ha sido cuidadosamente instruida para responder solo en el contexto de las enseñansas de neville")
                            
                            
                            //Lienzo
                            Text("☘️ Lienzo <Versión Extendida>: Una forma creativa de diseñar tus propios fondos con imágines, colores y texto. Ideal para compartir frases y pensamientos en redes sociales y con amigos")
                            
                            //Recordatorios:
                            Text("☘️ Recordatorios <Versión Extendida>: Ahora podemnos programar avisos para no olvidar realizar las tareas del día: meditaciones, leer, orar, dar gracias, afirmaciones, lista de compras, etc.")
                            
                            //Atajos
                            Text("☘️ Atajos & Comandos de Siri <Versión Extendida>: Se han creado varios Atajos, visible en la App Atajos, para realizar las siguientes acciones:")
                            VStack(alignment: .leading, spacing: 5){
                                Text("🔸Abrir el Diario:").foregroundStyle(.orange)
                                Text("Abre directamente la ventana del Diario. \nComandos de Siri:")
                                (
                                    Text("<Oye Siri> en la ley abre diario\n<Oye Siri> en la ley abre mi diario")
                                        .foregroundColor(.indigo)
                                        .italic()
                                )
                                
                                Text("\n🔸Crear entrada del Diario:").foregroundStyle(.orange)
                                Text("Crea una entrada de diario sin abrir la aplicación, de manera silenciosa. \nComando de Siri:")
                                (
                                    Text("<Oye Siri> en la la ley crea una entrada")
                                        .foregroundColor(.indigo)
                                        .italic()
                                    +
                                    Text("\nSiri te pedirá la contraseña, un título y un contenidp para crear la entrada del Diario. Si la contraseña es confusa, conviene deletrearla de manera clara y pausada")
                                )
                                
                                Text("\n🔸Crear frase para Espacio Calma:").foregroundStyle(.orange)
                                Text("Crea una frase personal para Espacio Calma. \nComandos de Siri:")
                                (
                                    Text("<Oye Siri> en la la ley crea una frase para calma \n<Oye Siri> en la Ley crea una frase personal para calma")
                                        .foregroundColor(.indigo)
                                        .italic()
                                    +
                                    Text("\nSiri pedirá que le dicte el texto de la Frase")
                                )
                                
                                Text("\n🔸Crear una actividad en la Agenda:").foregroundStyle(.orange)
                                Text("Crea una actividad en la Agenda. \nComandos de Siri:")
                                (
                                    Text("<Oye Siri> en la la ley crea una actividad en agenda \n<Oye Siri> en la Ley crea entrada en agenda")
                                        .foregroundColor(.indigo)
                                        .italic()
                                    +
                                    Text("\nSiri pedirá que le dicte un título, una fecha y un contenido")
                                )
                                
                                Text("\n🔸Abrir las notas:").foregroundStyle(.orange)
                                Text("Abre la ventana de la lista de Notas en la Aplicación. \nComando de Siri:")
                                (
                                    Text("<Oye Siri> en la ley abre mis notas")
                                        .foregroundColor(.indigo)
                                        .italic()
                                    
                                )
                                
                                Text("\n🔸Crear una nota").foregroundStyle(.orange)
                                Text("Crea una nota de manera silenciosa, sin abrir la aplicación. \nComando de Siri:")
                                (
                                    Text("<Oye Siri> en la ley crea una nota")
                                        .foregroundColor(.indigo)
                                        .italic()
                                    +
                                    Text("\nSiri le pedirá que dicte un título y la nota")
                                )
                                
                                Text("\n🔸Crear una frase").foregroundStyle(.orange)
                                Text("Crea una frase personal de manera silenciosa, sin abrir la aplicación. \nComando de Siri:")
                                (
                                    Text("<Oye Siri> en la ley crea una frase")
                                        .foregroundColor(.indigo)
                                        .italic()
                                    +
                                    Text("\nSiri pedirá que dicte la nueva frase")
                                )
                                Text("\n🔸Abrir una Conferencia al azar").foregroundStyle(.orange)
                                Text("Abre la aplicación y muestra una conferencia al azar")
                                (
                                    Text("<Oye Siri> en la ley abre conferencia")
                                        .foregroundColor(.indigo)
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
                            .buttonStyle(.bordered)
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
            LinearGradient.AzulTecnologico()
        }
           
      
        
    }
    
}


#Preview {
    Novedades()
}
