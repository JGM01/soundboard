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
    @State private var editingSound: Sound?

    @StateObject private var sounds = SoundList()

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            if sounds.sounds.isEmpty {
                ContentUnavailableView {
                    Label("No sounds", systemImage: "waveform.slash")
                } description: {
                    Text("You don't have any saved sounds yet.")
                } actions: {
                    Button("Save sound") {
                        showingEditor = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(sounds.sounds.indices, id: \.self) { index in
                            soundButton(at: index)
                                .shadow(radius: 4)
                        }
                    }
                    .padding()
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            editingSound = nil
                            showingEditor = true
                        } label: {
                            Image(systemName: "plus")
                                .fontWeight(.semibold)
                        }
                        .accessibilityLabel("Add sound")
                    }
                }
                .sheet(isPresented: $showingEditor) {
                    NavigationStack {
                        if let sound = editingSound {
                            SoundEditorView(
                                soundToEdit: sound
                            ) { updatedSound in
                                if let idx = sounds.sounds.firstIndex(where: { $0.id == updatedSound.id }) {
                                    withAnimation {
                                        sounds.sounds[idx] = updatedSound
                                    }
                                }
                                editingSound = nil
                            }
                        } else {
                            SoundEditorView(
                                soundToEdit: nil
                            ) { newSound in
                                withAnimation {
                                    sounds.sounds.append(newSound)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func soundButton(at index: Int) -> some View {
        let sound = sounds.sounds[index]

        Button {
            // Short tap = play sound
            sounds.play(sound)
        } label: {
            VStack {
                sound.displayImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(sound.name)
                    .font(.caption)
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            
        }
        // Long-press context menu
        .contextMenu {
            Button {
                // update state and present sheet
                editingSound = sound
                DispatchQueue.main.async {
                    showingEditor = true
                }
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button {
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive) {
                withAnimation(.snappy) {
                    sounds.removeSound(at: index)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } preview: {
            ZStack {
                sound.displayImage
                    .resizable()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .scaledToFill()

                VStack {
                    Spacer()
                    Text(sound.name)
                        .font(.title).bold()
                        .padding()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
