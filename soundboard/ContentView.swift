//
//  ContentView.swift
//  soundboard
//
//  Created by Jacob Germana-McCray on 12/5/25.
//

import SwiftUI

struct ContentView: View {
    let items = Array(1...12)
    
    private let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items, id: \.self) { item in
                    ItemView(item: item)
                        .frame(height: 120)
                }
            }
            .padding()
        }
    }
}

struct ItemView: View {
    let item: Int
    
    var body: some View {
        Button(action: {
            
        }, label: {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.blue)
                VStack {
                    Spacer()
                    Text("Sound #\(item)")
                        .foregroundStyle(.black)
                }.padding()
            }
        })
    }
}

@MainActor class SoundList {
    var sounds: [Sound] = [] {
        didSet { save() }
    }
    
    private let saveURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("sounds.json")

    
    init() {
        load()
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
                  let decoded = try? JSONDecoder().decode([Sound].self, from: data) else { return }
            sounds = decoded
        }
    }
}

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

#Preview {
    ContentView()
}
