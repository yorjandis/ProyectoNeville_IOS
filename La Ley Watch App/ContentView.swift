//
//  ContentView.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 31/1/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    
    @State private var selectedTab = 1
    
    var body: some View {
      TabView(selection: $selectedTab) {
          
          NavigationStack{
              VStack{
                  Frases()
                  .ignoresSafeArea()
              }
              
          }.tag(1)
          
          /*
          NavigationStack{
              VStack{
                  Notas()
              }
              
          }.tag(2)
          */
             
      }
      
      .tabViewStyle(.page)
                
                
    }
    
   //Vistas
    /*
    struct Diario: View {
        
        @State var list = [CKRecord]()
        @State var showSheetOptionsFilter = false
        @State var runTask = true //Para cargar la lista la primera vez que se muestra la vista
        @State var asyncIsWorking = false //Indica que hay una tarea async ejecutandose
        @State private var showAlert = false
        @State private var alertMessage = ""
        
        var body: some View {
            
            ZStack {
                LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)
                
                VStack {
                    Text("Diario")
                        .fontDesign(.serif).foregroundStyle(.black).bold()
                        .frame(maxWidth: .infinity, alignment: .center).padding(.top, 5)
                    Divider()
                    
                    HStack{
                        Button{
                            Task{
                                self.asyncIsWorking = true
                                self.list.removeAll()
                                list = await getList().reversed()
                                runTask = false
                                self.asyncIsWorking = false
                            }
                        }label: {
                            Image(systemName: "arrow.triangle.2.circlepath").foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        
                        
                        Spacer()
                        
                        Button{
                            self.showSheetOptionsFilter = true
                        }label: {
                            Image(systemName: "text.magnifyingglass").foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        }.buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        NavigationLink{
                            AddDiario()
                        }label: {
                            Image(systemName: "plus").foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                    }
                    .padding(.horizontal, 20)
                    
                    Divider()
                    
                    
                    List{
                        ForEach(self.list, id: \.recordID) {record in
                            NavigationLink{
                                ScrollView {
                                    Text(record.value(forKey: TDiario.CD_content.txt) as? String ?? "")
                                }
                            }label: {
                                VStack {
                                    HStack{
                                        Text(emotion(record.value(forKey: TDiario.CD_emotion.txt) as? String ?? ""))
                                            .font(.system(size: 28))
                                        Text(record.value(forKey: TDiario.CD_title.txt) as? String ?? "")
                                            .foregroundStyle(.black)
                                        Spacer()
                                    }
                                    Text((record.value(forKey: TDiario.CD_fecha.txt) as? Date ?? Date.now).formatted(date: .long, time: .omitted))
                                        .font(.system(size: 10, weight: .medium, design: .serif)).foregroundStyle(.black)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                
                            }
                            .swipeActions(edge: .trailing){
                                Button{
                                    Task{
                                        self.asyncIsWorking = true
                                        if await  iCloudDiario().Delete(record: record) {
                                            self.alertMessage = "Se ha eliminado la entrada"
                                            self.list.removeAll()
                                            list    = await getList().reversed()
                                            runTask = false
                                        }else{
                                            self.alertMessage = "Error al eliminar la entrada. inténtelo de nuevo"
                                        }
                                        self.asyncIsWorking = false
                                        self.showAlert = true
                                    }
                                    
                                }label: {
                                    Image(systemName: "trash")
                                        .tint(.red)
                                }
                            }
                        }
                        
                        
                    }
                    
                    .overlay(content: { //Muestra una barra de progreso si hay una tarea async ejecutándose...
                        if self.asyncIsWorking {
                            ProgressView()
                        }
                    })
                    .task{
                        if runTask {
                            self.asyncIsWorking = true
                            self.list.removeAll()
                            list    = await getList().reversed()
                            runTask = false //Pone a false para que no se vuelva a ejecutar al inicio
                            self.asyncIsWorking = false
                        }
                        
                        
                    }
                }
                .overlay {
                    if self.list.isEmpty && !self.asyncIsWorking {
                        Text("Nada que mostrar").foregroundStyle(.primary).bold()
                    }
                }
                
            }
            .alert(isPresented : $showAlert){
                Alert(title: Text("Diario"), message: Text(self.alertMessage))
            }
            .sheet(isPresented: $showSheetOptionsFilter) {
                FilterByDiarioView(listRecord: $list, showListOptions: $showSheetOptionsFilter)
            }
            
        }
        
        //Aux: Devuelve el emoticono segun el texto: Para funciones de filtrado
        private func emotion(_ txt: String)->String{
            switch txt {
            case "neutral" : "🙂"
            case "feliz": "😃"
            case "enfadado": "😤"
            case "desanimado": "😔"
            case "sorpresa": "😲"
            case "distraido": "🙄"
            default: ""
            }
        }
        
        //Aux: Devuelve el listado:
        private func getList()async ->[CKRecord]{
            /*
             let model = iCloudKitModel(of: .BDPrivada)
             return await model.getRecords(tableName: TableName.CD_Diario)
             */
            return []
        }
        
        
    }
    
    struct Notas: View {
        
        @State var list = [CKRecord]()
        @State var showSheetOptionsFilter = false
        @State var runTask = true //Para cargar la lista la primera vez que se muestra la vista
        @State var asyncIsWorking = false //Indica que hay una tarea async ejecutandose
        @State private var showAlert = false
        @State private var alertMessage = ""

        var body: some View {
            
            ZStack {
                LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)
                
                VStack {
                    Text("Notas")
                        .fontDesign(.serif).foregroundStyle(.black).bold()
                        .frame(maxWidth: .infinity, alignment: .center).padding(.top, 5)
                    Divider()
                    HStack{
                        Button{
                            Task{self.asyncIsWorking = true
                                self.list.removeAll()
                                list = await getList().reversed()
                                runTask = false
                                self.asyncIsWorking = false
                            }
                        }label: {
                            Image(systemName: "arrow.triangle.2.circlepath").foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                               
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        Button{
                            self.showSheetOptionsFilter = true
                        }label: {
                            Image(systemName: "text.magnifyingglass").foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        }.buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        NavigationLink{
                            AddNota()
                        }label: {
                            Image(systemName: "plus").foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    
                        Divider()
     
                    
                    List(self.list, id: \.recordID){ record in
                        NavigationLink{
                            ScrollView {
                                Text(record.value(forKey: TNotas.CD_nota.txt) as? String ?? "")
                            }
                        }label: {
                           Text(record.value(forKey: TNotas.CD_title.txt) as? String ?? "").fontDesign(.serif).foregroundStyle(.black)
                                .frame(height: 10)
                        }
                        .swipeActions(edge: .leading){
                            Button{
                                Task{
                                    /*
                                    self.asyncIsWorking = true
                                    if  await iCloudKitModel(of: .BDPrivada).DeleteRecord(record: record){
                                        self.alertMessage = "Se ha eliminadio la nota"
                                        self.list.removeAll()
                                        self.list = await getList()
                                    }else{
                                        self.alertMessage = "Error al eliminar la nota. Inténtelo de nuevo"
                                    }
                                    self.asyncIsWorking = false
                                    self.showAlert = true
                                    */
                                }
                                
                            }label: {
                                Image(systemName: "trash")
                                    .tint(.red)
                            }
                        }
                        
                    }
                    .overlay(content: { //Muestra una barra de progreso si hay una tarea async ejecutándose...
                        if self.asyncIsWorking {
                            ProgressView()
                        }
                    })
                    .task{
                        if runTask {
                            self.asyncIsWorking = true
                            self.list.removeAll()
                            list = await getList().reversed()
                            runTask = false
                            self.asyncIsWorking = false
                        }
                        
                        
                }
                }
                .overlay {
                    if self.list.isEmpty && !self.asyncIsWorking {
                        Text("Nada que mostrar").foregroundStyle(.primary).bold()
                    }
                }
                
            }
            .sheet(isPresented: $showSheetOptionsFilter, content: {
                FilterByNotaView(listRecord: self.$list, showListOptions: self.$showSheetOptionsFilter)
            })
        }
        
        //Aux obtiene el listado
        private func getList() async -> [CKRecord]{
            /*
            let model = iCloudKitModel(of: .BDPrivada)
            return await model.getRecords(tableName: TableName.CD_Notas)
            */
            return []
        }
        
        
    }

  */
    
    
    struct Frases : View {
        @State private var frase : String = UtilFuncs.FileReadToArray("listfrases").randomElement() ?? ""
        var body: some View {
            ZStack{
                LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)
                
                VStack(alignment: .center){
                    Text("La Ley").bold()
                        .padding(.bottom, 10)
                    ScrollView{
                        Text(frase)
                            .italic()
                            .padding(.horizontal, 5)
                            .padding(.bottom, 20)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .onTapGesture {
                                frase = UtilFuncs.FileReadToArray("listfrases").randomElement() ?? ""
                            }
                    }
                    
                }
                .padding(.top, 10)
                .fontDesign(.serif)
                .font(.system(size: 20))
                .foregroundStyle(.black)
            }
            
        }
    }
    
}

#Preview {
    ContentView()
}
