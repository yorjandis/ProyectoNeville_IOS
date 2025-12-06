//
//  Lienzo_Fondos.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 22/11/25.
//

import SwiftUI
#if os(iOS)
import PhotosUI
#endif

struct GradientTemplate: Identifiable {
    let id = UUID()
    var colors: [Color]
}

struct Lienzo_Fondo: View {
    
    @EnvironmentObject var lienzoModel : LienzoModel
    
    @State private var manualColor1 : Color = .purple
    @State private var manualColor2 : Color = .green
    
    
    
#if os(iOS)
//Para seleccionar una imagen de la galería:
@StateObject private var photosPicker = ImagePickerViewModel()
//Para mostrar el selector de imagen dentro del context menu de la imagen en iOS:
@State private var mostrarPicker = false
@State private var selectedItem: PhotosPickerItem?
#endif
    
    //Aplicando la imagen de fondo:
    @AppStorage(LienzoModel.key_imagenFondoAplicada) var imagenFondoAplicada: Bool = false
    
    
    // Lista ampliada de degradados
    let gradients: [GradientTemplate] = [
        GradientTemplate(colors: [Color(red: 0.95, green: 0.93, blue: 0.92),
                                  Color(red: 0.92, green: 0.65, blue: 0.40)]),
        GradientTemplate(colors: [Color(red: 0.95, green: 0.93, blue: 0.92),
                                  Color(red: 0.85, green: 0.85, blue: 0.85)]),
        GradientTemplate(colors: [Color(red: 0.55, green: 0.75, blue: 0.89),
                                  Color(red: 0.55, green: 0.75, blue: 0.89)]),
        GradientTemplate(colors: [Color(red: 0.96, green: 0.60, blue: 0.60),
                                  Color(red: 0.96, green: 0.60, blue: 0.60)]),
        GradientTemplate(colors: [Color(red: 0.38, green: 0.38, blue: 0.38),
                                  Color(red: 0.29, green: 0.29, blue: 0.29)]),

        // Nuevos degradados vibrantes
        GradientTemplate(colors: [Color.pink, Color.purple]),
        GradientTemplate(colors: [Color.orange, Color.red]),
        GradientTemplate(colors: [Color.yellow, Color.orange]),
        GradientTemplate(colors: [Color.blue, Color.purple]),
        GradientTemplate(colors: [Color.green, Color.teal]),
        
        // Combinaciones más contrastadas
        GradientTemplate(colors: [Color(red: 0.10, green: 0.70, blue: 1.00),
                                  Color(red: 0.80, green: 0.00, blue: 0.60)]),
        GradientTemplate(colors: [Color(red: 0.95, green: 0.20, blue: 0.40),
                                  Color(red: 1.00, green: 0.80, blue: 0.20)]),
        GradientTemplate(colors: [Color(red: 0.20, green: 0.95, blue: 0.60),
                                  Color(red: 0.00, green: 0.40, blue: 0.90)]),
        
        // Degradados neón/fluor
        GradientTemplate(colors: [Color(red: 0.00, green: 1.00, blue: 0.80),
                                  Color(red: 0.60, green: 0.00, blue: 1.00)]),
        GradientTemplate(colors: [Color(red: 1.00, green: 0.00, blue: 0.80),
                                  Color(red: 1.00, green: 0.90, blue: 0.00)]),
        
        // Estilo “sunset”
        GradientTemplate(colors: [Color(red: 1.00, green: 0.60, blue: 0.00),
                                  Color(red: 0.80, green: 0.00, blue: 0.30)]),
        
        // Estilo “tropical”
        GradientTemplate(colors: [Color(red: 0.05, green: 0.95, blue: 0.80),
                                  Color(red: 0.10, green: 0.60, blue: 0.95)]),
        
        // Estilo “aurora”
        GradientTemplate(colors: [Color(red: 0.15, green: 0.95, blue: 0.40),
                                  Color(red: 0.20, green: 0.30, blue: 0.90)])
    ]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    
  
 

    var body: some View {
        ScrollView {
            
            
            VStack(spacing: 20) {
                //Sección para cargar una imagen de fondo
                VStack{
                    Text("Imagen de fondo")
                    #if os(macOS)
                    //Cargar una imagen de una carpeta
                    Button("Seleccionar Imagen..."){
                        if let image = seleccionarImagen(){
                            lienzoModel.imagenFondo = image
                            self.imagenFondoAplicada = true //Activa el flag para aplicar la imagen de fondo
                        }
                    }
                    #else
                    //Cargar una imagen de la galeria
                    VStack(alignment: .leading){
                        PhotosPicker(
                            selection: $photosPicker.selectedItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Text("Cargar imagen de la galería...")
                                    .font(.headline)
                                    .padding()
                                    .foregroundColor(.white)
                                    .background(.blue)
                                    .cornerRadius(8)
                            }
                            .font(.headline)
                            
                    }
                    .buttonStyle(.plain)
                    .onChange(of: photosPicker.selectedItem) { _, _ in
                        photosPicker.loadImage()
                    }
                    .onChange(of: photosPicker.selectedImage) { _, nueva in
                        if let nueva = nueva {
                            lienzoModel.imagenFondo = nueva
                            self.imagenFondoAplicada = true //Activa el flag para aplicar la imagen del fondo
                        }
                    }
                    #endif
                }
                
                //Colores personalizados:
                VStack {
                    Text("Selecciona tus colores")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 20){
                        VStack{
                            ColorPicker("Color 1", selection: $manualColor1)
                            ColorPicker("Color 2", selection: $manualColor2)
                        }
                        .frame(width: 100)
                        
                        
                        Button {
                            //Guardo los colores custom y de fondo actuales
                            self.lienzoModel.saveColorFondo(tipoColor: .custom)
                            self.lienzoModel.saveColorFondo(tipoColor: .lienzo)
                            
                            //Desactivo la imagen de fondo:
                            self.imagenFondoAplicada = false
                            
                            //Cargando los colores
                            self.lienzoModel.coloresFondo1 = self.lienzoModel.coloresFondoCustom1
                            self.lienzoModel.coloresFondo2 = self.lienzoModel.coloresFondoCustom2
                            

                        } label: {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [self.lienzoModel.coloresFondoCustom1, self.lienzoModel.coloresFondoCustom2] ),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 150, height: 100)
                                .overlay(
                                    ZStack{
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                        
                                        Text("Aplicar Color")
                                            .foregroundStyle(manualColor1.adaptiveTextColorForGradient(manualColor1, manualColor2))
                                    }
                                    
                                )
                                .shadow(radius: 5)
                        }
                        .buttonStyle(.plain)
                        
                    }
                    .padding()
                    .onChange(of: self.manualColor1) { _ , newValue in
                        //self.lienzoModel.coloresFondo = [newValue, manualColor2]
                        self.lienzoModel.coloresFondoCustom1 = newValue
                        
                    }
                    .onChange(of: self.manualColor2) { _ , newValue in
                       // self.lienzoModel.coloresFondo = [manualColor1, newValue]
                        self.lienzoModel.coloresFondoCustom2 = newValue
                    }
                }
                .padding()
                .onAppear {
                    //Restaura los colores custom del usuario:
                        self.manualColor1 = lienzoModel.coloresFondoCustom1
                        self.manualColor2 = lienzoModel.coloresFondoCustom2
                }
                // --- Selección Manual FIN ---
            }
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(gradients) { gradient in
                    Button {
                        
                        //Desactivo la imagen de fondo:
                        self.imagenFondoAplicada = false
                        
                        self.lienzoModel.coloresFondo1 = gradient.colors[0]
                        self.lienzoModel.coloresFondo2 = gradient.colors[1]
                        
                        self.lienzoModel.saveColorFondo(tipoColor: .lienzo)
                    } label: {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: gradient.colors),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                            .shadow(radius: 5)
                    }
                    .buttonStyle(.plain)
                    
                }
            }
            .padding()
        }
    }
}

