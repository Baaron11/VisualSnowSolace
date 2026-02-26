// CameraPreviewView.swift
// Visual Snow Solace
//
// UIViewRepresentable that wraps an AVCaptureVideoPreviewLayer for live
// camera preview. Used by LensModeView to show the rear camera feed
// underneath colour-tint overlays.

import SwiftUI

#if canImport(UIKit)
import UIKit
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.previewLayer.session = session
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
