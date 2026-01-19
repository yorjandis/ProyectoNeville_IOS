//
//  PlayerPreview.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 27/12/25.
//

//Permite reproducir un tono de los almacenados en el bundle:

import SwiftUI
import AVFoundation

@MainActor
final class NotificationSoundPreview {

    static let shared = NotificationSoundPreview()
    private var player: AVAudioPlayer?

    func play(_ sound: NotificationSound) {
        stop()

        guard sound != .default,
              let url = Bundle.main.url(
                forResource: sound.rawValue,
                withExtension: "caf"
              )
        else { return }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            msg("❌ Error reproduciendo sonido:", error)
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
