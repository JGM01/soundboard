//
//  SoundEditorView.swift
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

struct SoundEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Callback to deliver the new sound to the parent
    let onSave: (Sound) -> Void
    
    // Form data
    @State private var name: String = ""
    @State private var imageData: Data?
    @State private var previewImage: Image?
    
    // Pickers
    @State private var imageSelection: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showFileImporter = false
    @State private var showRecorder = false
    
    @State private var localAudioURL: URL?
    
    @StateObject private var recorder = AudioRecorder()
    
    var body: some View {
        NavigationStack {
            Form {
                
                Section("Name") {
                    TextField("Sound name", text: $name)
                        .textInputAutocapitalization(.words)
                }
                
                Section("Image") {
                    VStack {
                        HStack {
                            Spacer()
                            if let img = previewImage {
                                img
                                    .resizable()
                                    .frame(width: 180, height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .scaledToFill()
                                    .padding()
                            } else {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.secondary)
                                    .frame(height: 180)
                            }
                            Spacer()
                        }
                        
                        
                        HStack {
                            Spacer()
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
                            Spacer()
                        }
                    }
                }
                Section("Audio") {
                    if let localAudioURL {
                        Label {
                            Text(localAudioURL.deletingPathExtension().lastPathComponent)
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    } else {
                        Text("No audio selected")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
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
            .navigationTitle("New Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAndDismiss() }
                        .bold()
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView { uiImage in
                    if let data = uiImage.jpegData(compressionQuality: 0.85) {
                        imageData = data
                        previewImage = Image(uiImage: uiImage)
                    }
                }
            }
            .fileImporter(isPresented: $showFileImporter,
                          allowedContentTypes: [.audio],
                          allowsMultipleSelection: false) { result in
                handleFileImport(result)
            }
            .sheet(isPresented: $showRecorder) {
                RecorderSheet(recorder: recorder) { recordedURL in
                    localAudioURL = recordedURL
                }
                .presentationDetents([.height(260), .medium])
            }
            .onChange(of: imageSelection) { oldItem, newItem in
                guard let newItem else {
                    previewImage = nil
                    imageData = nil
                    return
                }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            previewImage = Image(uiImage: uiImage)
                            imageData = data
                        }
                    }
                }
            }
        }
    }
    
    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        localAudioURL != nil
    }
    
    func handleFileImport(_ result: Result<[URL], Error>) {
        guard let url = try? result.get().first else { return }
        
        do {
            let copiedURL = try copyToDocumentsWithUUID(url: url)
            localAudioURL = copiedURL
        } catch {
            print("Failed to copy audio file: \(error)")
        }
    }
        
    func copyToDocumentsWithUUID(url: URL) throws -> URL {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let ext = url.pathExtension.lowercased()
        let newName = UUID().uuidString + (ext.isEmpty ? "" : ".\(ext)")
        let destination = docs.appendingPathComponent(newName)
        
        // Remove any previous temp file if exists (safe)
        try? fm.removeItem(at: destination)
        try fm.copyItem(at: url, to: destination)
        return destination
    }
        
    
    func saveAndDismiss() {
        guard let audioURL = localAudioURL else { return }
        
        let sound = Sound(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            bgImageData: imageData,
            audioFileName: audioURL.lastPathComponent
        )
        
        onSave(sound)
        dismiss()
    }
}