Visual Snow Solace
A free, open-source iOS app for people living with Visual Snow Syndrome (VSS) and related visual disturbances.

Disclaimer: Visual Snow Solace is not a medical device. It is not intended to diagnose, treat, cure, or prevent any medical condition. All tools and exercises in this app are for informational and self-support purposes only. Always consult a qualified clinician before starting any new visual or therapeutic program. Stop immediately if you feel unwell.


What Is This App?
Visual Snow Syndrome is a neurological condition causing persistent visual disturbances — static, afterimages, light sensitivity, floaters, and more — often accompanied by non-visual symptoms like tinnitus, brain fog, and sleep difficulties.
Visual Snow Solace provides a collection of self-support tools that some people with VSS find helpful for managing daily symptoms. It is built by someone in the VSS community, for the VSS community.

Features
🏠 Home
A clear dashboard with quick access to all tools.
🫁 Breathing
Guided breathing exercises with animated visual feedback and haptic pacing.

Box Breathing (4-4-4-4)
4-7-8 Breathing
Paced Breathing (5-5)
Animated expanding/contracting circle
Respects iOS Reduce Motion — switches to text-only countdown when enabled

🔊 Static Audio
A noise generator using AVAudioEngine.

White noise — uniform random samples
Pink noise — Voss-McCartney algorithm
Brown noise — Brownian integration
Volume slider, low-pass filter cutoff slider (200 Hz – 20 kHz)
Optional animated visual grain with speed, contrast, and hue controls
Fullscreen grain mode

👁 Visual Training
Lens Mode

Live camera preview with adjustable color tint overlay
Preset tints: Warm (FL-41 approx.), Cool, Gray, Amber, Green
Opacity slider, low-luminance toggle (caps brightness at 30%)

Eye Movement Exercises

Lens Mode color overlay

Binocular & Convergence Exercises

Brock String
Pencil Push-Ups
Barrel Cards
Convergence Stereogram (cat and circles images, toggleable)
Lifesaver Cards (instructions)

Hart Chart & Tracking

Standard 10×10 randomized Hart Chart (letters + numbers, regenerated each session)
4 Corner Black & White (four independent 4×4 grids)
4 Corner Color (adjacency-constrained red/orange/green/blue)
Built-in metronome (20–120 BPM) with haptic beat
Shuffle button for fresh chart every time

Michigan Tracking

Underline mode (trace through a letter grid, circling A→Z)
Eye-only mode (tap targets without underlining)
Session timer and personal best tracking

Red/Green Word Training

Full Dolch sight word list (~315 words)
Alternating red/green columns for use with anaglyphic glasses
Shuffle, column count (2 or 4), and font size controls

🩺 Symptoms
An educational gallery covering common VSS symptoms:
Visual Symptoms

Visual Snow
Palinopsia (Afterimages)
Double Vision (Diplopia)
Photophobia (Light Sensitivity)
Nyctalopia (Night Blindness)
Entoptic Phenomena (Floaters)

Non-Visual Symptoms

Tinnitus
Brain Fog
Anxiety, Depression & Irritability
Sleep Difficulties
Dizziness
Vertigo
Depersonalization-Derealization (DPDR)

🔬 Research
Curated links to peer-reviewed and clinical VSS resources:

NIH GARD — Visual Snow Syndrome overview
Visual Snow Initiative — Patient guide
PubMed 2024 — VSS clinical review
PMC 2025 — Clinical characteristics study
Eye on Vision Foundation — Clinical research journal

⚡ Quick Relief
One-tap combination: brown noise + Box breathing + optional visual grain, all in a single screen.
📋 Log
A daily symptom journal stored entirely on-device.

Date, severity slider (1–10), triggers, notes
Swipe to delete
Reverse-chronological list

⚙️ Settings

Appearance: System / Light / Dark
Reduce Motion override
Default breathing preset
About and legal disclaimers


Privacy
No data ever leaves your device.

All symptom logs, settings, and preferences are stored locally using UserDefaults.
The camera (used in Lens Mode) is processed on-device in real time and is never recorded, stored, or transmitted.
No analytics, no advertising, no third-party tracking of any kind.

Full privacy policy: visualsnowsolace privacy policy

How to Build
Requirements

Xcode 15 or later
iOS 16.0+ deployment target
Swift 5.9+
A physical device is required for camera features (Lens Mode). All other features run in Simulator.

Steps

Clone the repository:

bash   git clone https://github.com/yourusername/Visual-Snow-Solace.git

Open Visual Snow Solace.xcodeproj in Xcode.
Select your development team under Signing & Capabilities.
Build and run on a simulator or device (iOS 16+).

No third-party dependencies. No package manager setup required.

Design Decisions
SwiftUI + @Observable
The entire UI is built in SwiftUI targeting iOS 17+ (using @Observable). This keeps the architecture clean and forward-compatible.
AVAudioEngine for noise generation
AVAudioSourceNode gives sample-level control for implementing white, pink, and brown noise algorithms without external libraries. The pink noise implementation uses the Voss-McCartney algorithm; brown noise uses Brownian integration of white noise.
Core Image / TimelineView for visual grain
The animated grain in Static Audio uses TimelineView + Canvas with an xorshift64 PRNG seeded from the timeline date. This is CPU-based but lightweight enough for this use case and avoids Metal complexity. A Metal upgrade path exists if performance becomes a concern on older devices.
AVCaptureSession for Lens Mode
A UIViewRepresentable wrapping AVCaptureVideoPreviewLayer provides live camera preview. The color tint is applied as a SwiftUI .overlay with .blendMode(.multiply) — simple, performant, and requires no CoreImage pipeline.
Safety defaults throughout
Reduce Motion is respected in every animated view. Break reminders fire at 5 minutes in all exercise views. The camera permission string clearly explains the use case to both users and App Store reviewers.
All data on-device
UserDefaults with JSON encoding handles all persistence. No CloudKit, no network calls, no accounts.

Future Directions

Metal-based procedural visual noise — higher performance grain with GPU rendering
Vision Pro support — visor overlay mode for spatial computing
Advanced tint filtering — Core Image pipelines for more precise FL-41 simulation
iCloud sync — optional symptom log backup
Notification reminders — daily breathing or exercise reminders
Expanded research library — more curated papers with in-app summaries


Safety & App Store Guidance
This app makes no medical claims. All in-app copy uses language like:

"These tools may help reduce discomfort for some people. They are not a medical treatment. Consult your clinician."

The disclaimer is displayed persistently in relevant screens. The App Store description explicitly states this is not a medical device.
Reviewers: the camera permission is used exclusively for the Lens Mode color overlay feature in Visual Training. No camera data is stored or transmitted.

License
MIT License. See LICENSE for details.

Contributing
Issues and pull requests welcome. If you have VSS and want to suggest a feature or correction, please open an issue — lived experience feedback is especially valued.

Built for the VSS community. Not a medical device. Consult your clinician.
