//
//  Sound.swift
//  soundboard
//
//  Created by Jacob Germana-McCray on 12/5/25.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let soundboard = UTType(exportedAs: "com.jgm01.soundboard.sound")
}

struct Sound: Codable, Equatable, Identifiable, Transferable {

    var id = UUID()
    let name: String
    let color: Color
    let audioFileName: String
    
    static var transferRepresentation: some TransferRepresentation {
        // 1. Share as a pretty JSON file (e.g. "My Sound.soundboard")
        FileRepresentation(contentType: .soundboard) { sound in
            // Encode the Sound metadata to JSON
            let encoder = JSONEncoder()
            let data = try encoder.encode(sound)
            
            // Temporary URL for the JSON file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(sound.name)
                .appendingPathExtension("soundboard")
            try data.write(to: tempURL)
            return SentTransferredFile(tempURL)
        } importing: { received in
            let data = try Data(contentsOf: received.file)
            return try JSONDecoder().decode(Sound.self, from: data)
        }

        // 2. Also include the actual audio file so the receiver gets the sound
        ProxyRepresentation(exporting: \.audioURL)
    }
    
    // MARK: - Codable Keys
    private enum CodingKeys: String, CodingKey {
        case id, name, colorData, audioFileName
    }
    
    // MARK: - Init (from decoder)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.audioFileName = try container.decode(String.self, forKey: .audioFileName)
        
        if let colorData = try container.decodeIfPresent(Data.self, forKey: .colorData),
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            self.color = Color(uiColor)
        } else {
            self.color = .blue // fallback color
        }
    }
    
    // MARK: - Encode
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(audioFileName, forKey: .audioFileName)
        
        // Modern, non-deprecated archiving
        let uiColor = UIColor(color)
        let colorData = try NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: true)
        try container.encode(colorData, forKey: .colorData)
    }
    
    // Convenience inits
    init(name: String, color: Color, audioFileName: String) {
        self.name = name
        self.color = color
        self.audioFileName = audioFileName
    }
    
    init(id: UUID, name: String, color: Color, audioFileName: String) {
        self.id = id
        self.name = name
        self.color = color
        self.audioFileName = audioFileName
    }
    
    var audioURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(audioFileName)
    }
}

