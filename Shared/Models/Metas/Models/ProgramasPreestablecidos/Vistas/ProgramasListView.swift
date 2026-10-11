//
//  ProgramasPreestablecidosView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 18/2/26.
//

import SwiftUI
import CoreData

struct ProgramasListView: View {
    let embeddedInPanel: Bool

    @StateObject private var viewModel = ProgramasViewModel()
#if os(iOS)
    @State private var selectedPanelGroupTitle: String?
    @State private var selectedPanelPrograms: [ProgramasPreestablecido]?
    @State private var selectedPanelProgram: ProgramasPreestablecido?
#endif

    init(embeddedInPanel: Bool = false) {
        self.embeddedInPanel = embeddedInPanel
    }

    @ViewBuilder
    var body: some View {
#if os(iOS)
        if embeddedInPanel {
            embeddedPanelContent
        } else {
            standardNavigationContent
        }
#else
        standardNavigationContent
#endif
    }

    private var standardNavigationContent: some View {
        NavigationStack {
            ZStack{
                
                LinearGradient.FondoOscuro()
                    .ignoresSafeArea()
                
                List {

                    ForEach(viewModel.programasAgrupados,id: \.0) { grupo, programas in
                        #if os(macOS)
                        
                        Button(programas.count == 1 ? programas.first!.title : ProgramaArchivo.localizedGroupTitle(for: grupo)) {
                            showWindow(for: SubMenuView(programas: programas),
                                       environmentObjects: [],
                                       title: "",
                                       size: .absolute(CGSize(width: 500, height: 600)),
                                       isModal: true)
                        }
                        
                        #else
                        
                        NavigationLink(
                            programas.count == 1 ? programas.first!.title : ProgramaArchivo.localizedGroupTitle(for: grupo)

                        ) {

                            SubMenuView(programas: programas)
                        }
                        
                        #endif
                        
                        
                    }

                }
                .scrollContentBackground(.hidden)   // 🔥 clave
                .background(Color.clear) 
            }
            
            .navigationTitle("Programas")
        }
    }

#if os(iOS)
    /// Navegación local para el espacio de trabajo de iPad. No utiliza
    /// `NavigationLink`, evitando que la pila exterior de Metas sustituya toda
    /// la pantalla al abrir un grupo o el detalle de un programa.
    private var embeddedPanelContent: some View {
        ZStack {
            LinearGradient.FondoOscuro()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    if selectedPanelPrograms != nil || selectedPanelProgram != nil {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedPanelProgram != nil {
                                    selectedPanelProgram = nil
                                } else {
                                    selectedPanelPrograms = nil
                                    selectedPanelGroupTitle = nil
                                }
                            }
                        } label: {
                            Label("Volver", systemImage: "chevron.left")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Volver a Programas")
                    }

                    Text(panelTitle)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .frame(height: 46)

                Divider()

                if let selectedPanelProgram {
                    ProgramaDetailView(programa: selectedPanelProgram)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let selectedPanelPrograms {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(selectedPanelPrograms) { programa in
                                ProgramCard(
                                    programa: programa,
                                    onShowDetails: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedPanelProgram = programa
                                        }
                                    },
                                    onProgramStarted: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            self.selectedPanelPrograms = nil
                                            selectedPanelGroupTitle = nil
                                        }
                                    }
                                )
                                .padding(.horizontal, 10)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                } else {
                    List {
                        ForEach(viewModel.programasAgrupados, id: \.0) { grupo, programas in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedPanelGroupTitle = programas.count == 1
                                        ? programas.first?.title
                                        : ProgramaArchivo.localizedGroupTitle(for: grupo)
                                    selectedPanelPrograms = programas
                                }
                            } label: {
                                HStack {
                                    Text(
                                        programas.count == 1
                                            ? programas.first?.title ?? grupo
                                            : ProgramaArchivo.localizedGroupTitle(for: grupo)
                                    )
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            }
        }
    }

    private var panelTitle: String {
        selectedPanelProgram?.title ?? selectedPanelGroupTitle ?? "Programas"
    }
#endif

    struct SubMenuView: View {
        
        let programas: [ProgramasPreestablecido]
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            ZStack{
                
                LinearGradient.FondoOscuro()
                    .ignoresSafeArea()
                VStack{
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            
                            ForEach(programas) { programa in
                                
                                ProgramCard(programa: programa)
                                    .padding(.horizontal, 3)
                            }
                        }
                    }
                    
                    #if os(macOS)
                    if ventanaActualEsModal() {
                        Button("Cerrar"){
                            if let window = NSApp.keyWindow {
                                closeWindow(window)
                                
                            }
                        }
                        .padding()
                        .help("Cerrar")
                    }
                    #endif
                    
                    
                }
                
                
            }
            
            .navigationTitle("Programas")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
    
    
    struct ProgramCard :  View {
        
        @Environment(\.dismiss) var dismiss
        
        @Environment(\.managedObjectContext) private var context
        
        let programa : ProgramasPreestablecido
        var onShowDetails: (() -> Void)? = nil
        var onProgramStarted: (() -> Void)? = nil
        
        var body: some View {


                VStack(alignment: .leading, spacing: 12) {
                    
                    Text(programa.title)
                        .font(.title3)
                        .foregroundStyle(.black)
                        .bold()
                    
                    Text(programa.description)
                        .font(.body)
                        .bold()
                        .foregroundStyle(.black)
                        .lineLimit(3)
                    
                   
                    
                    HStack {
                        #if os(macOS)
                        Button{
                            showWindow(for: ProgramaDetailView(programa: programa),
                            environmentObjects: [],
                                       title: GoalsL10n.text(
                                           "goals.ui.program_information",
                                           fallback: "Información del Programa"
                                       ),
                                       size: .percentage(width: 0.4, height: 0.7),
                                       isModal: true
                            )
                            
                        } label: {
                            Label("Detalles...", systemImage: "info.circle")
                                .font(.headline)
                        }
                        .tint(.black)
                        .buttonStyle(.bordered)
                        
                        #else
                        if let onShowDetails {
                            Button(action: onShowDetails) {
                                Label("Detalles...", systemImage: "info.circle")
                                    .font(.headline)
                            }
                            .tint(.black)
                            .buttonStyle(.bordered)
                        } else {
                            NavigationLink {
                                ProgramaDetailView(programa: programa)
                            } label: {
                                Label("Detalles...", systemImage: "info.circle")
                                    .font(.headline)
                            }
                            .tint(.black)
                            .buttonStyle(.bordered)
                        }
                        
                        #endif
                        

                        Spacer()
                        
                        Button{
                            ProgramasViewModel.createProgramaPreestablecido(
                                programa: programa,
                                context: context
                            )
                            if let onProgramStarted {
                                onProgramStarted()
                            } else {
                                dismiss()
                            }
                        }label: {
                            Label("Comenzar Programa", systemImage: "figure.run.circle")
                                .font(.headline)
                        }
                        .tint(.black)
                        .buttonStyle(.bordered)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient.Oceano())
                        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                )
  
        }
        
        
    }
    
    
}
