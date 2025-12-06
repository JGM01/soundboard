//
//  RecorderSheet.swift
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

struct RecorderSheet: View {
    @ObservedObject var recorder: AudioRecorder
    var onFinish: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text(recorder.isRecording ? "Recording…" : "Ready to Record")
                .font(.headline)

            HStack(spacing: 32) {
                Button {
                    do {
                        _ = try recorder.startRecording()
                    } catch {
                        // Handle permission or start error
                        print("Recording error:", error)
                    }
                } label: {
                    Label("Record", systemImage: "circle.fill")
                }
                .disabled(recorder.isRecording)

                Button {
                    if let url = recorder.stopRecording() {
                        onFinish(url)
                    }
                    dismiss()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .disabled(!recorder.isRecording)
            }
        }
        .padding()
    }
}