//
//  ListFavView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 20/10/23.
//
//Listado de favoritos para Frases y Conferencias txt

import SwiftUI
import CoreData

struct ListFavView: View {
    @Environment(\.dismiss) var dimiss
    @State var typeContent : TypeOfContent = .frases
    @State var ButtonActive: Bool = true //true para frase, false para conf
    
    @State  private var arrayTxt : [FavTxt] = []
    @State  private var arrayFrases : [Frases] = []
    @State  private  var showSheetContentTxt = false
    
     
   
  
    var body: some View {
        NavigationStack{
            
            VStack{
                HStack(spacing: 40){
                    Button("Frases"){
                        ButtonActive = true //Activa el botón
                        typeContent = .frases
                    }
                    .modifier(ButtonActive ?  GradientButtonStyle(ancho: 80) : GradientButtonStyle(ancho: 80, colors: [.gray, .brown]) )
                    
                    Button("Otros"){
                        ButtonActive = false //Activa el botón
                        typeContent = .NA
                    }
                        .modifier(ButtonActive ?  GradientButtonStyle(ancho: 80, colors: [.gray, .brown]) : GradientButtonStyle(ancho: 80) )
                }
                Divider()
                
                switch typeContent{
                case .frases:
                    List(arrayFrases){item in
                        RowFrases(item: item, array: $arrayFrases)
                           
                    }
                    .onAppear{
                        arrayFrases.removeAll()
                        arrayFrases = manageFrases().getFavFrases()
                    }
                default:
                    List(arrayTxt){item in
                        RowTxt(item: item, array: $arrayTxt)
                            
                    }
                    .onAppear{
                        arrayTxt.removeAll()
                        arrayTxt = FavModel().getAllFavTxt()
                    }
                }
                Spacer()
                Divider()
                HStack(spacing: 30){
                    Spacer()
                    Button("Volver"){
                        dimiss()
                    }
                    .padding(.trailing, 20)
                }.padding(.bottom, 20)
            }
            .padding(.top,20)
            .navigationTitle("Favoritos")
            .navigationBarTitleDisplayMode(.inline)

        }
    }
    
    //item de frase
    struct RowFrases : View{
        let item : Frases
        @Binding var array : [Frases]
        
        
        var body: some View{
            Text(item.frase ?? "")
                .swipeActions(edge: .trailing){
                    Button("Quitar Favorito"){
                        manageFrases().updateFavState(fraseID: item.id ?? "", statusFav: false)
                        array.removeAll()
                        array = manageFrases().getFavFrases()
                    }
                    .tint(.red)
                }
        }
        
        
    }
    
    //Item de fichero txt
    struct RowTxt : View{
        let item : FavTxt //El identity actual
        @Binding var array : [FavTxt]
        
        var typeContent : TypeOfContent{
            switch item.prefix{
            case "conf_":
                return .conf
            case "preg_":
                return .preguntas
            case "cita_":
                return .citas
            case "ayud_":
                return .ayudas
            default:
                return .NA
            }
        }
        
        var body: some View{
            HStack{
                NavigationLink{
                    ContentTxtShowView(fileName: item.namefile ?? "", title: item.namefile ?? "", typeContent: typeContent)
                }label: {
                    Text("\(item.namefile ?? "")")
                    Spacer()
                    Text("\(item.prefix ?? "")")
                }
                
            }
                .swipeActions(edge: .trailing){
                    Button("Quitar Favorito"){
                        FavModel().Delete(nameFile: item.namefile?.lowercased() ?? "", prefix: item.prefix ?? "")
                        array.removeAll()
                        array = FavModel().getAllFavTxt()
                        
                    }
                    .tint(.red)
                }
        }
        
        
    }
}

#Preview {
    ContentView()
}
