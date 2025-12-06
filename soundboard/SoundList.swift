//
//  SoundList.swift
//  soundboard
//
//  Created by Jacob Germana-McCray on 12/5/25.
//

import AVFoundation
import Combine
import SwiftUI

@MainActor
final class SoundList: ObservableObject {
    @Published var sounds: [Sound] = [] {
        didSet { save() }
    }

    private var player: AVAudioPlayer?

    private let saveURL: URL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("sounds.json")

    init() {
        load()
    }

    func play(_ sound: Sound) {
        do {
            player = try AVAudioPlayer(contentsOf: sound.audioURL)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Failed to play sound:", error)
        }
    }

    private func save() {
        Task {
            if let data = try? JSONEncoder().encode(sounds) {
                try? data.write(to: saveURL)
            }
        }
    }

    private func load() {
        Task {
            guard let data = try? Data(contentsOf: saveURL),
                  let decoded = try? JSONDecoder().decode([Sound].self, from: data)
            else { return }
            sounds = decoded
        }
    }
    
    func removeSound(at index: Int) {
        sounds.remove(at: index)
    }

    func removeSound(_ sound: Sound) {
        sounds.removeAll { $0.id == sound.id }
    }
}

