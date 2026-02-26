// LensModeView.swift
// Visual Snow Solace
//
// Live camera preview with configurable colour-tint overlays.
// Users can pick from preset tints (Warm / FL-41, Cool, Gray, Amber, Green),
// adjust tint opacity, and enable a "low luminance" mode that caps overlay
// brightness at 30 %. Falls back to a placeholder when camera permission
// is denied or unavailable.

import SwiftUI

#if canImport(UIKit)
import AVFoundation
#endif

// MARK: - Tint Presets

enum TintPreset: String, CaseIterable, Identifiable {
    case warm = "Warm (FL-41)"
    case cool = "Cool"
    case gray = "Gray"
    case amber = "Amber"
    case green = "Green"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .warm:   return TintPreset.warmColor
        case .cool:   return TintPreset.coolColor
        case .gray:   return TintPreset.grayColor
        case .amber:  return TintPreset.amberColor
        case .green:  return TintPreset.greenColor
        }
    }

    // Named colour constants
    static let warmColor  = Color(red: 0.85, green: 0.45, blue: 0.55)  // FL-41 rose
    static let coolColor  = Color(red: 0.40, green: 0.55, blue: 0.80)
    static let grayColor  = Color(red: 0.50, green: 0.50, blue: 0.50)
    static let amberColor = Color(red: 0.90, green: 0.70, blue: 0.30)
    static let greenColor = Color(red: 0.40, green: 0.70, blue: 0.40)
}

// MARK: - Camera Manager

#if canImport(UIKit)
@Observable
class CameraManager {
    let session = AVCaptureSession()
    var permissionGranted = false
    var permissionDenied = false

    func requestAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.permissionGranted = granted
                    self.permissionDenied = !granted
                    if granted { self.configureSession() }
                }
            }
        default:
            permissionDenied = true
        }
    }

    func startRunning() {
        guard permissionGranted, !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func stopRunning() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                    for: .video,
                                                    position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)
        session.commitConfiguration()
    }
}
#endif

// MARK: - Lens Mode View

struct LensModeView: View {
    @State private var selectedTint: TintPreset = .warm
    @State private var tintOpacity: Double = 0.4
    @State private var lowLuminance = false

    #if canImport(UIKit)
    @State private var cameraManager = CameraManager()
    #endif

    private var effectiveOpacity: Double {
        lowLuminance ? min(tintOpacity, 0.30) : tintOpacity
    }

    var body: some View {
        VStack(spacing: 0) {
            cameraArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            controls
        }
        .navigationTitle("Lens Mode")
        #if canImport(UIKit)
        .onAppear {
            cameraManager.requestAccess()
        }
        .onChange(of: cameraManager.permissionGranted) { _, granted in
            if granted { cameraManager.startRunning() }
        }
        .onDisappear {
            cameraManager.stopRunning()
        }
        #endif
    }

    // MARK: - Camera Area

    @ViewBuilder
    private var cameraArea: some View {
        #if canImport(UIKit)
        if cameraManager.permissionDenied {
            deniedFallback
        } else if cameraManager.permissionGranted {
            CameraPreviewView(session: cameraManager.session)
                .overlay(
                    selectedTint.color
                        .opacity(effectiveOpacity)
                        .blendMode(.multiply)
                )
                .ignoresSafeArea(edges: .top)
                .accessibilityLabel("Live camera preview with \(selectedTint.rawValue) tint")
        } else {
            ProgressView("Requesting camera access…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        #else
        deniedFallback
        #endif
    }

    private var deniedFallback: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Camera access is required for Lens Mode.")
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Open Settings → Privacy → Camera to grant access.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Camera permission denied. Open Settings to grant access.")
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 16) {
            // Tint preset picker
            Picker("Tint", selection: $selectedTint) {
                ForEach(TintPreset.allCases) { preset in
                    Text(preset.rawValue).tag(preset)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Tint preset picker")

            // Opacity slider
            HStack {
                Text("Opacity")
                    .font(.subheadline)
                Slider(value: $tintOpacity, in: 0...1)
                    .accessibilityLabel("Tint opacity, \(Int(tintOpacity * 100)) percent")
                Text("\(Int(tintOpacity * 100))%")
                    .font(.subheadline.monospacedDigit())
                    .frame(width: 44, alignment: .trailing)
            }

            // Low luminance toggle
            Toggle("Low Luminance", isOn: $lowLuminance)
                .accessibilityLabel("Low luminance mode, limits overlay to 30 percent maximum")

            DisclaimerFooter()
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
