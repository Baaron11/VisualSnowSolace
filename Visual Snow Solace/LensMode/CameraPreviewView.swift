// CameraPreviewView.swift
// Visual Snow Solace
//
// SwiftUI wrapper around an AVCaptureVideoPreviewLayer for live camera
// preview. Automatically starts and stops the capture session in response
// to the view appearing and disappearing, ensuring the session survives
// navigation and is never recreated unnecessarily.

import SwiftUI

#if canImport(UIKit)
import UIKit
import AVFoundation

// MARK: - Public wrapper

/// Drop-in SwiftUI view that displays a live camera preview.
///
/// The caller must own the `AVCaptureSession` (e.g. as `@State` in the
/// parent view) and pass it in.  `CameraPreviewView` takes care of
/// starting / stopping the session on appear / disappear so the parent
/// does not need to manage lifecycle.
struct CameraPreviewView: View {
    let session: AVCaptureSession

    var body: some View {
        CameraPreviewRepresentable(session: session)
            .onAppear {
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                guard status == .authorized else { return }
                DispatchQueue.global(qos: .userInitiated).async {
                    if !session.isRunning {
                        session.startRunning()
                    }
                }
            }
            .onDisappear {
                DispatchQueue.global(qos: .userInitiated).async {
                    if session.isRunning {
                        session.stopRunning()
                    }
                }
            }
    }
}

// MARK: - UIViewRepresentable (internal)

/// Thin UIKit bridge – only responsible for hosting the preview layer.
/// Session start / stop is handled by the enclosing `CameraPreviewView`.
private struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        // Session binding is handled in makeUIView; nothing to update.
    }

    // Custom UIView subclass so the preview layer is the backing layer,
    // which keeps it resized automatically.
    class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
#endif
