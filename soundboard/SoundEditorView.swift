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
    @State private var imageData: Data?
    @State private var previewImage: Image?

    @State private var imageSelection: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showFileImporter = false
    @State private var showRecorder = false

    @State private var localAudioURL: URL?

    @StateObject private var recorder = AudioRecorder()

    private var isEditing: Bool { soundToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Name
                Section("Name") {
                    TextField("Sound name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                // MARK: - Image
                Section("Image") {
                    VStack {
                        HStack {
                            Spacer()
                            if let img = previewImage {
                                img
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 180, height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.secondary)
                                    .frame(height: 180)
                            }
                            Spacer()
                        }

                        HStack(spacing: 20) {
                            PhotosPicker(selection: $imageSelection, matching: .images) {
                                Label("Photos", systemImage: "photo.on.rectangle")
                            }
                            .buttonStyle(.bordered)

                            Button {
                                showCamera = true
                            } label: {
                                Label("Camera", systemImage: "camera")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top, 8)
                    }
                }

                // MARK: - Audio
                Section("Audio") {
                    if let url = localAudioURL {
                        Label {
                            Text(url.deletingPathExtension().lastPathComponent)
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    } else {
                        Text("No audio selected")
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 20) {
                        Button {
                            showFileImporter = true
                        } label: {
                            Label("Files", systemImage: "folder")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            showRecorder = true
                        } label: {
                            Label("Record", systemImage: "mic")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
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
            // MARK: - Sheets & Importers
            .sheet(isPresented: $showCamera) {
                CameraView { uiImage in
                    guard let data = uiImage.jpegData(compressionQuality: 0.85) else { return }
                    imageData = data
                    previewImage = Image(uiImage: uiImage)
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
            .onChange(of: imageSelection) { _, newItem in
                Task {
                    guard let newItem,
                          let data = try? await newItem.loadTransferable(type: Data.self),
                          let uiImage = UIImage(data: data)
                    else { return }

                    await MainActor.run {
                        self.imageData = data
                        self.previewImage = Image(uiImage: uiImage)
                    }
                }
            }
            // MARK: - Populate fields when editing
            .onAppear {
                guard isEditing, name.isEmpty else { return }

                name = soundToEdit?.name ?? ""
                imageData = soundToEdit?.bgImageData
                if let data = soundToEdit?.bgImageData,
                   let uiImage = UIImage(data: data) {
                    previewImage = Image(uiImage: uiImage)
                }

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
            bgImageData: imageData,
            audioFileName: audioURL.lastPathComponent
        )

        onSave(sound)
        dismiss()
    }
}
