//
//  ContentView.swift
//  soundboard
//
//  Created by Jacob Germana-McCray on 12/5/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation
import UIKit
import Combine

struct ContentView: View {
    @State private var showingEditor = false
    
    let items = Array(1...12)
    @StateObject private var sounds = SoundList()
    
    private let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
    
    var body: some View {
        if sounds.sounds.isEmpty {
            ContentUnavailableView {
                Label("No sounds", systemImage: "waveform.slash")
            } description: {
                Text("You don't have any saved sounds yet.")
            } actions: {
                Button("Save sound") {
                    showingEditor.toggle()
                }
                .buttonStyle(.borderedProminent)
            }
            .sheet(isPresented: $showingEditor) {
                SoundEditorView { sound in
                    sounds.sounds.append(sound)
                }
            }
        } else {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(sounds.sounds.indices, id: \.self) { index in
                        let sound = sounds.sounds[index]

                        Button {
                            sounds.play(sound)
                        } label: {
                            VStack {
                                sound.displayImage
                                    .resizable()
                                    .frame(width: 96, height: 96)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                Text(sound.name)
                                    .foregroundStyle(.black)
                            }
                        }
                    }
                }
                
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditor.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                SoundEditorView { sound in
                    sounds.sounds.append(sound)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

