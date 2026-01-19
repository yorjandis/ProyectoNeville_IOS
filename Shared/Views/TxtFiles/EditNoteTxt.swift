//
//  EditNoteTxt.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 17/12/25.
//
import SwiftUI

//Permite ver y editar el campo nota
struct EditNoteTxt:View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var context
    
    @StateObject var modeloTxt : TxtContentModel = TxtContentModel.shared
    let nameTxt : String
    let typeOfContent : TipoDeContenido
    
    @FocusState  private var focus: Bool
    @State private var textfiel = ""
    
    //Funcion de autosalvado
    @State private var isActive = true
    @State private var isNew = true //Si es true significa que el contenido del TextField ha cambiado
    @State private var oldContent: String = "" //Almacena en cada salvado una copia del contenido de la Nota para ver si este ha cambiado.
    
    // Contador en segundos para resetear el temporizador de autosave
    @State private var timeReset: Int = 3
    @State private var autosaveTimerRef: Timer? = nil
    
    
    var body: some View {
        NavigationStack{
            ZStack{
                LinearGradient(colors: [.black.opacity(0.7), .brown], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(){
                    TextEditor(text: $textfiel)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 22))
                        .foregroundStyle( self.isNew ? .blue : .primary).italic().bold()
                        .padding(10)
                        .cornerRadius(20)
                        .focused(self.$focus)
                        .onAppear{
                            textfiel = modeloTxt.getNotaOfTXT(nombreTxt: self.nameTxt, type: typeOfContent )
                            self.focus = true
                        }
                        .onChange(of: self.textfiel, { oldValue, newValue in
                            self.isNew = true
                            // Reinicia el contador y reprograma el autosave 3s despues del último input
                            resetAutosaveTimer()
                        })
                        
                    
                    Spacer()
                }
            }
            
            .navigationTitle("Notas")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .onAppear {
                isActive = true
                
            }
            .onDisappear {
                isActive = false
                autosaveTimerRef?.invalidate()
                autosaveTimerRef = nil
            }
            .toolbar{
#if os(macOS)
                if ventanaActualEsModal(){
                    ToolbarItem(placement: .navigation) {
                        Button{
                            if let window = NSApp.keyWindow {
                                closeWindow(window)
                            }
                        }label:{
                            Label("Cerrar", systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .help("Cerrar")
                    }
                }
                
#endif

                
            }
        }
    }
    

    
    //Funciones de AutoSave:
    private func resetAutosaveTimer() {
        guard isActive else { return }
        autosaveTimerRef?.invalidate()
        autosaveTimerRef = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeReset), repeats: false) { _ in
            Task{ @MainActor in
                autoSave() //Una véz finalizado el tiempo, se lanza la función
            }
            
        }
        // Asegura que el timer corre en los modos comunes (para seguir en scrolls, etc.)
        RunLoop.main.add(autosaveTimerRef!, forMode: .common)
    }

    private func cancelAutosaveTimer() {
        autosaveTimerRef?.invalidate()
        autosaveTimerRef = nil
    }
    
    private func autoSave(){
        msg("Salvando el contenido")
        if self.oldContent != self.textfiel{
            if modeloTxt.setNotaOfTXT(nombreTxt: nameTxt, type: self.typeOfContent, nota: textfiel){
                modeloTxt.getAllFileTxtOfType(type: self.typeOfContent)
                self.oldContent = self.textfiel //Actualiza el contenido de la variable para volver a comparar
                self.isNew = false //resetea el flag que indica que el contenido ha cambiado
                
            }
        }
    }
    
    
}
