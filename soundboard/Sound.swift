//
//  Sound.swift
//  soundboard
//
//  Created by Jacob Germana-McCray on 12/5/25.
//

import SwiftUI

struct Sound: Codable, Equatable {
    var id = UUID()
    let name: String
    let bgImageData: Data?
    let audioFileName: String

    init(name: String, bgImageData: Data?, audioFileName: String) {
        self.name = name
        self.bgImageData = bgImageData
        self.audioFileName = audioFileName
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case bgImageData
        case audioFileName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.bgImageData = try container.decodeIfPresent(Data.self, forKey: .bgImageData)
        self.audioFileName = try container.decode(String.self, forKey: .audioFileName)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(bgImageData, forKey: .bgImageData)
        try container.encode(audioFileName, forKey: .audioFileName)
    }
    
    var audioURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(audioFileName)
    }
        
    var displayImage: Image {
        if let data = bgImageData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "waveform")
    }
    
    static func == (lhs: Sound, rhs: Sound) -> Bool { lhs.id == rhs.id }
}
