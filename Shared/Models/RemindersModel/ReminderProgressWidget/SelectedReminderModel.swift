import SwiftUI
import Observation
import Combine


//Fuente de verdad para los widget de recordatorios
/*
 Mantiene un listado de recordatorios selectos, sincronizados con  el listado actual de recordatorios disponibles.
 */

@MainActor
final class SelectedReminderModel: ObservableObject {

    @Published var selectedReminders: [StoredReminder] = [] //Listado de Recordatorios selectos en home

    private var selectedIDs: [String] = []
    
    static var shared = SelectedReminderModel() //Singleton
    
    private let store : ReminderStore //Acceso al modelo que almacena los recordatorios: Para extraer los recordatorios almacenados.
    
    private let selectedIDsKey = "SelectedReminderIDs" //Clave para persistr los recordatorios

    init() {
        self.store = ReminderStore.shared //Carga el modelo que inicia los recordatorios
        observeStoreChanges()           //Inicia el observador del Notification Center
        store_LoadSelectedIDs()         //Cargando el listado de IDs almacenado
        updateSelectedReminders()       //Actualizando los recordatorio de acuerdo al listado de IDs
        
    }

    //Adiciona un nuevo ID de recordatorio a la lista selecta
    func select(_ reminder: StoredReminder) {
        //Evitar duplicados
        if !selectedIDs.contains(reminder.id) {
            //Adiciona el recordatorio a la lista de ids
            selectedIDs.append(reminder.id)
            
            store_SaveSelectedIDs()            // ← Persistencia
            
            //Actualiza el listado de recordatorios
            updateSelectedReminders()
        }
    }

    //Quita un nuevo recordatorio a la lista selecta
    func deselect(_ reminder: StoredReminder) {
        selectedIDs.removeAll { $0 == reminder.id }
        
        store_SaveSelectedIDs()            // ← Persistencia
        
        updateSelectedReminders()
    }

    //Remueve todos los recordatorios
    func clearSelection() {
        selectedIDs.removeAll()
        store_SaveSelectedIDs()            // ← Persistencia
        updateSelectedReminders()
    }

    //Determina si un recordatorio existe en la lista:
    func existingRemindersId(_ reminder: StoredReminder) -> Bool {
        return selectedIDs.contains(reminder.id)
    }
    
    //Reacciona a los cambios: actualizando la lista de recordatorios según el listados de IDs actual.
    private func observeStoreChanges() {
        NotificationCenter.default.addObserver(
            forName: .reminderStoreDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task{ @MainActor in
                self?.updateSelectedReminders()
            }
            
        }
    }

    //Recarga los recordatorios según el listado de IDs. Trabajo con la función observeStoreChanges
    private func updateSelectedReminders() {
        let all = store.load() //Carga todos los recordatorios
        selectedReminders = all.filter { selectedIDs.contains($0.id) && $0.isStarted } //Filtra solo los ID de los recordatorios selectos
    }
    
  //Almacenando y recuperando el listado de IDs:
    
    //Cargando la lista almcenada
    private func store_LoadSelectedIDs() {
        selectedIDs = UserDefaults.standard.stringArray(forKey: selectedIDsKey) ?? []
    }

    //Persistiendo la lista almacenada
    private func store_SaveSelectedIDs() {
        UserDefaults.standard.set(selectedIDs, forKey: selectedIDsKey)
    }
    
    
}

//Nombre para la notificación interna para notificar cambios:
extension Notification.Name {
    static let reminderStoreDidChange = Notification.Name("reminderStoreDidChange")
}
