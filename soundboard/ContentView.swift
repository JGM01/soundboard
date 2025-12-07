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
    @State private var soundToEdit: Sound?

    @StateObject private var sounds = SoundList()

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            if sounds.sounds.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "waveform.slash")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    
                    Text("No sounds")
                        .font(.title2.bold())
                    
                    Text("You don't have any saved sounds yet.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title)
                            .fontWeight(.semibold)
                            
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .buttonBorderShape(.circle)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(sounds.sounds.indices, id: \.self) { index in
                            soundButton(at: index)
                        }
                    }
                    .padding()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            soundToEdit = nil
                            showingEditor = true
                        } label: {
                            Image(systemName: "plus")
                                .fontWeight(.semibold)
                        }
                        .accessibilityLabel("Add sound")
                    }
                }

                // THE FIXED SHEET — no NavigationStack, no if/else
                .sheet(isPresented: $showingEditor) {
                    SoundEditorView(soundToEdit: soundToEdit) { savedSound in
                        if let index = sounds.sounds.firstIndex(where: { $0.id == savedSound.id }) {
                            sounds.sounds[index] = savedSound
                        } else {
                            sounds.sounds.append(savedSound)
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
            sounds.play(sound)
        } label: {
            VStack {
                ZStack {
                    Circle()
                        .fill(sound.color.gradient)
                        .frame(width: 96, height: 96)
                        .overlay(
                            // inset shadow
                            Circle()
                                .strokeBorder(
                                    sound.color.mix(with: .black, by: 0.3),
                                    lineWidth: 12
                                )
                                .blur(radius: 4)
                                .offset(x: 4, y: 4)
                                .mask(Circle().fill(.black)) // cuts it to inner edge only
                                .blendMode(.multiply)
                        )
                        .overlay(
                            // inner highlight
                            Circle()
                                .strokeBorder(sound.color.mix(with: .white, by: 0.5), lineWidth: 12)
                                .blur(radius: 4)
                                .offset(x: -2, y: -2)
                                .mask(Circle().fill(.black))
                                .blendMode(.lighten)
                        )
                        .clipShape(Circle())
                               

                }
                .frame(width: 96, height: 96)

                Text(sound.name)
                    .font(.caption)
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            
        }
        .buttonStyle(PressableEmissiveButtonStyle())
        // Long-press context menu
        .contextMenu {
            Button {
                // update state and present sheet
                soundToEdit = sound
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
            VStack {
                ZStack {
                    Circle()
                        .fill(sound.color.gradient)
                        .frame(width: 96, height: 96)
                        .overlay(
                            // inset shadow
                            Circle()
                                .strokeBorder(
                                    sound.color.mix(with: .black, by: 0.3),
                                    lineWidth: 12
                                )
                                .blur(radius: 4)
                                .offset(x: 4, y: 4)
                                .mask(Circle().fill(.black)) // cuts it to inner edge only
                                .blendMode(.multiply)
                        )
                        .overlay(
                            // inner highlight
                            Circle()
                                .strokeBorder(sound.color.mix(with: .white, by: 0.5), lineWidth: 12)
                                .blur(radius: 4)
                                .offset(x: -2, y: -2)
                                .mask(Circle().fill(.black))
                                .blendMode(.lighten)
                        )
                        .clipShape(Circle())
                               

                }
                .frame(width: 96, height: 96)

                Text(sound.name)
                    .font(.headline).bold()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 36)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

struct PressableEmissiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .offset(y: configuration.isPressed ? 3 : 0)
            .overlay(
                Circle()
                    .fill(.white.opacity(configuration.isPressed ? 0.6 : 0))
                    .blur(radius: configuration.isPressed ? 22 : 0)
                    .scaleEffect(configuration.isPressed ? 1.2 : 0.8)
            )
            .animation(.snappy(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
