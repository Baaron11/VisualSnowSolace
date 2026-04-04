// LensModeView.swift
// Visual Snow Solace
//
// Live camera preview with configurable colour-tint overlays.
// Users can pick from preset tints (Warm / FL-41, Cool, Gray, Amber, Green),
// adjust tint opacity, and enable a "low luminance" mode that caps overlay
// brightness at 30 %. Falls back to a placeholder when camera permission
// is denied or unavailable.

import SwiftUI
import Foundation

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

    var localizedName: String {
        switch self {
        case .warm:  return NSLocalizedString("lensMode.tint.warm", comment: "Warm FL-41 tint preset name")
        case .cool:  return NSLocalizedString("lensMode.tint.cool", comment: "Cool tint preset name")
        case .gray:  return NSLocalizedString("lensMode.tint.gray", comment: "Gray tint preset name")
        case .amber: return NSLocalizedString("lensMode.tint.amber", comment: "Amber tint preset name")
        case .green: return NSLocalizedString("lensMode.tint.green", comment: "Green tint preset name")
        }
    }

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
        .navigationTitle(NSLocalizedString("lensMode.title", comment: "Lens Mode navigation title"))
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
                .accessibilityLabel(String(format: NSLocalizedString("lensMode.camera.preview.accessibility", comment: "Camera preview accessibility with tint name"), selectedTint.localizedName))
        } else {
            ProgressView(NSLocalizedString("lensMode.camera.requestingAccess", comment: "Camera access request in progress"))
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
            Text(NSLocalizedString("lensMode.camera.denied.title", comment: "Camera access required message"))
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(NSLocalizedString("lensMode.camera.denied.instructions", comment: "Instructions to grant camera access"))
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(NSLocalizedString("lensMode.camera.denied.accessibility", comment: "Camera denied accessibility label"))
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 16) {
            // Tint preset picker
            Picker(NSLocalizedString("lensMode.tint.picker", comment: "Tint picker label"), selection: $selectedTint) {
                ForEach(TintPreset.allCases) { preset in
                    Text(preset.localizedName).tag(preset)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(NSLocalizedString("lensMode.tintPicker.accessibility", comment: "Tint preset picker accessibility"))

            // Opacity slider
            HStack {
                Text(NSLocalizedString("lensMode.opacity", comment: "Opacity label"))
                    .font(.subheadline)
                Slider(value: $tintOpacity, in: 0...1)
                    .accessibilityLabel(String(format: NSLocalizedString("lensMode.opacity.accessibility", comment: "Tint opacity accessibility"), Int(tintOpacity * 100)))
                Text("\(Int(tintOpacity * 100))%")
                    .font(.subheadline.monospacedDigit())
                    .frame(width: 44, alignment: .trailing)
            }

            // Low luminance toggle
            Toggle(NSLocalizedString("lensMode.lowLuminance", comment: "Low luminance toggle"), isOn: $lowLuminance)
                .accessibilityLabel(NSLocalizedString("lensMode.lowLuminance.accessibility", comment: "Low luminance accessibility"))

            DisclaimerFooter()
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
