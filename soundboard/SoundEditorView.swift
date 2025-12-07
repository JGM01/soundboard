//
//  SoundEditorView.swift
//  soundboard
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

struct SoundEditorView: View {
    @Environment(\.dismiss) private var dismiss

    // Input
    let soundToEdit: Sound?           // nil = create new, non-nil = edit existing
    let onSave: (Sound) -> Void       // called with updated or new Sound

    // Form state
    @State private var name: String = ""
    @State private var color: Color = .red

    @State private var showFileImporter = false
    @State private var showRecorder = false

    @State private var localAudioURL: URL?

    @StateObject private var recorder = AudioRecorder()

    private var isEditing: Bool { soundToEdit != nil }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Sound name", text: $name)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.words)
                        .multilineTextAlignment(.center)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    
                    VStack {
                        ColorPicker(
                            selection: $color,
                            supportsOpacity: false,
                            label: {
                                Text("Button Color")
                            }
                        )
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(.capsule)
                    }
                    .padding()
                    
                    VStack {
                        HStack {
                            Spacer()
                            if let url = localAudioURL {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.title)
                                    Spacer()
                                    Text(url.deletingPathExtension().lastPathComponent)
                                        .lineLimit(1)
                                }
                            } else {
                                Text("No audio selected")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        

                        HStack {
                            Button {
                                showFileImporter = true
                            } label: {
                                Label(title: {
                                    Text("Select")
                                }, icon: {
                                    Image(systemName: "folder")
                                        .foregroundStyle(.primary)
                                })
                            }
                            .buttonStyle(.glassProminent)
                            .buttonBorderShape(.capsule)

                            Spacer()
                            
                            Button(role: .destructive) {
                                showRecorder = true
                            } label: {
                                Label(title: {
                                    Text("Record")
                                }, icon: {
                                    Image(systemName: "mic")
                                        .foregroundStyle(.primary)
                                })
                            }
                            .buttonStyle(.glassProminent)
                            .buttonBorderShape(.capsule)
                        }
                        .padding()
                    }
 
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            .padding()
            .listStyle(.plain)
            .navigationTitle(isEditing ? "Edit Sound" : "New Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                    .bold()
                    .disabled(!canSave)
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .sheet(isPresented: $showRecorder) {
                RecorderSheet(recorder: recorder) { recordedURL in
                    localAudioURL = recordedURL
                }
                .presentationDetents([.height(260), .medium])
            }
            // MARK: - Populate fields when editing
            .onAppear {
                guard isEditing, name.isEmpty else { return }

                name = soundToEdit?.name ?? ""
                color = soundToEdit?.color ?? .red

                // Reconstruct audio URL from stored filename
                if let fileName = soundToEdit?.audioFileName {
                    let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    localAudioURL = docsURL.appendingPathComponent(fileName)
                }
            }
        }
    }

    // MARK: - Helpers

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        localAudioURL != nil
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard let url = try? result.get().first else { return }

        let copiedURL = copyToDocumentsWithUUID(url: url)
        localAudioURL = copiedURL
    }

    private func copyToDocumentsWithUUID(url: URL) -> URL {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let ext = url.pathExtension.lowercased()
        let newName = UUID().uuidString + (ext.isEmpty ? "" : ".\(ext)")
        let destination = docs.appendingPathComponent(newName)

        try? fm.removeItem(at: destination)
        try? fm.copyItem(at: url, to: destination)
        return destination
    }

    private func saveAndDismiss() {
        guard let audioURL = localAudioURL else { return }

        let sound = Sound(
            id: soundToEdit?.id ?? UUID(), // preserve ID when editing
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            color: color,
            audioFileName: audioURL.lastPathComponent
        )

        onSave(sound)
        dismiss()
    }
}

#Preview("Creating New Sound") {
    SoundEditorView(soundToEdit: nil) { sound in
        print("Created:", sound.name)
    }
}

#Preview("Editing Existing Sound") {
    SoundEditorView(soundToEdit: Sound(
        name: "Laugh Track",
        color: .yellow,
        audioFileName: "laugh.m4a"
    )) { sound in
        print("Edited:", sound.name)
    }
}

#Preview("New Sound – Dark Mode") {
    SoundEditorView(soundToEdit: nil) { _ in }
        .preferredColorScheme(.dark)
}
