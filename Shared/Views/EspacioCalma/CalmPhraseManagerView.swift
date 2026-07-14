import SwiftUI
import CoreData

private struct CalmPhraseManagerItem: Identifiable {
    let objectID: NSManagedObjectID
    let phrase: String
    let createdAt: Date

    var id: NSManagedObjectID { objectID }
}

struct CalmPhraseManagerView: View {
    @State private var items: [CalmPhraseManagerItem] = []
    @State private var newPhraseDraft: String = ""
    @State private var isMultiSelectionMode: Bool = false
    @State private var selectedItemIDs: Set<NSManagedObjectID> = []
    @State private var showDeleteSelectedConfirmation: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                TextField("Escribe una frase personalizada", text: $newPhraseDraft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...3)

                Button("Agregar") {
                    addPhrase(from: newPhraseDraft)
                }
                .buttonStyle(.bordered)
                .disabled(newPhraseDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            if isMultiSelectionMode && !items.isEmpty {
                HStack(spacing: 10) {
                    Button("Marcar todo") {
                        selectedItemIDs = Set(items.map(\.id))
                    }
                    .buttonStyle(.bordered)

                    Button("Desmarcar") {
                        selectedItemIDs.removeAll()
                    }
                    .buttonStyle(.bordered)

                    Button("Invertir") {
                        let allIDs = Set(items.map(\.id))
                        selectedItemIDs = allIDs.subtracting(selectedItemIDs)
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                }
                .padding(.horizontal, 14)
            }

            List {
                if items.isEmpty {
                    Text("No hay frases de usuario todavía.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(items) { item in
                        HStack(alignment: .top, spacing: 10) {
                            if isMultiSelectionMode {
                                Image(systemName: selectedItemIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedItemIDs.contains(item.id) ? .blue : .secondary)
                                    .padding(.top, 2)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.phrase)
                                    .foregroundStyle(.primary)
                                Text(item.createdAt, format: .dateTime.day().month().year().hour().minute())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard isMultiSelectionMode else { return }
                            toggleSelection(for: item)
                        }
                    }
                    .onDelete(perform: deletePhrases)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Frases de Espacio Calma")
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(L10n.exact(isMultiSelectionMode ? "Desactivar selección múltiple" : "Activar selección múltiple")) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isMultiSelectionMode.toggle()
                            if !isMultiSelectionMode {
                                selectedItemIDs.removeAll()
                            }
                        }
                    }

                    Button("Borrar seleccionadas", role: .destructive) {
                        showDeleteSelectedConfirmation = true
                    }
                    .disabled(selectedItemIDs.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "¿Deseas borrar \(selectedItemIDs.count) frase(s) seleccionada(s)?",
            isPresented: $showDeleteSelectedConfirmation,
            titleVisibility: .visible
        ) {
            Button("Borrar", role: .destructive) {
                deleteSelectedPhrases()
            }
            Button("Cancelar", role: .cancel) { }
        }
        .onAppear {
            reloadItems()
        }
    }

    private func hasCalmUserPhraseEntity() -> Bool {
        let model = CoreDataController.shared.context.persistentStoreCoordinator?.managedObjectModel
        return model?.entitiesByName["CalmUserPhrase"] != nil
    }

    private func reloadItems() {
        guard hasCalmUserPhraseEntity() else {
            items = []
            return
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: "CalmUserPhrase")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            let objects = try CoreDataController.shared.context.fetch(request)
            items = objects.compactMap { object in
                guard let phrase = (object.value(forKey: "phrase") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !phrase.isEmpty else {
                    return nil
                }
                let createdAt = (object.value(forKey: "createdAt") as? Date) ?? .distantPast
                return CalmPhraseManagerItem(objectID: object.objectID, phrase: phrase, createdAt: createdAt)
            }
            selectedItemIDs = selectedItemIDs.intersection(Set(items.map(\.id)))
        } catch {
            msg("Error cargando frases de usuario para Espacio Calma:", error)
            items = []
            selectedItemIDs.removeAll()
        }
    }

    private func addPhrase(from rawPhrase: String) {
        let phrase = rawPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !phrase.isEmpty else { return }
        guard hasCalmUserPhraseEntity() else { return }

        let context = CoreDataController.shared.context
        guard let entity = NSEntityDescription.entity(forEntityName: "CalmUserPhrase", in: context) else { return }
        let object = NSManagedObject(entity: entity, insertInto: context)
        object.setValue(UUID(), forKey: "id")
        object.setValue(phrase, forKey: "phrase")
        object.setValue(Date(), forKey: "createdAt")

        do {
            try context.save()
            newPhraseDraft = ""
            reloadItems()
        } catch {
            context.rollback()
            msg("Error guardando frase de usuario de Espacio Calma:", error)
        }
    }

    private func deletePhrases(at offsets: IndexSet) {
        guard hasCalmUserPhraseEntity() else { return }
        let targets = offsets.compactMap { index in
            items.indices.contains(index) ? items[index] : nil
        }

        let context = CoreDataController.shared.context
        for target in targets {
            if let object = try? context.existingObject(with: target.objectID) {
                context.delete(object)
            }
        }

        do {
            try context.save()
            withAnimation(.easeInOut(duration: 0.2)) {
                reloadItems()
            }
        } catch {
            context.rollback()
            msg("Error eliminando frases de usuario de Espacio Calma:", error)
        }
    }

    private func toggleSelection(for item: CalmPhraseManagerItem) {
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }

    private func deleteSelectedPhrases() {
        guard hasCalmUserPhraseEntity(), !selectedItemIDs.isEmpty else { return }
        let idsToDelete = selectedItemIDs
        let context = CoreDataController.shared.context

        for objectID in idsToDelete {
            if let object = try? context.existingObject(with: objectID) {
                context.delete(object)
            }
        }

        do {
            try context.save()
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedItemIDs.removeAll()
                isMultiSelectionMode = false
                reloadItems()
            }
        } catch {
            context.rollback()
            msg("Error eliminando frases de usuario de Espacio Calma:", error)
        }
    }
}

#Preview {
    NavigationStack {
        CalmPhraseManagerView()
    }
}
