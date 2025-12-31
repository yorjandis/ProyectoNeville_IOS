//
//  NotificationSound.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 27/12/25.
//

//Maneja del uso de Tonos para recordatorios

import NotificationCenter
import UserNotifications

enum NotificationSound: String, CaseIterable, Codable, Identifiable {
    case `default`
    case tono1
    case tono2
    case tono3
    case tono4
    case tono5
    case tono6
    case tono7
    case tono8
    case tono9
    case tono10
    case tono11
    case tono12
    case tono13
    case tono14
    case tono15
    case tono16
    case tono17
    case tono18
    case tono19
    case tono20
    case tono21
    case tono22
    case tono23
    case tono24
    case tono25
    case tono26
    case tono27
    case tono29
    case tono30
    
    
    var id: String { rawValue }
    
    private static let key = "selectedNotificationSound" //Clave de UserDefault donde almacenar el nombre del tono usado actualmente

    var displayName: String {
            self == .default ? "Por defecto" : rawValue.capitalized
        }
    
    var unSound: UNNotificationSound {
        switch self {
        case .default:
            return .default
        default:
            return UNNotificationSound(named: .init("\(rawValue).caf"))
        }
    }
    
    //Almacena el tono seleccionado en UserDefault:
    static var selected: NotificationSound {
            get {
                guard
                    let raw = UserDefaults.standard.string(forKey: key),
                    let sound = NotificationSound(rawValue: raw)
                else {
                    return .default
                }
                return sound
            }
            set {
                UserDefaults.standard.set(newValue.rawValue, forKey: key)
            }
        }
    
}
