// LogView.swift
// Visual Snow Solace
//
// Symptom log backed by UserDefaults JSON storage. Users can add entries
// with a severity rating (1–10), triggers, and notes. Entries are displayed
// in reverse-chronological order with swipe-to-delete.

import SwiftUI

// MARK: - Data Model

struct LogEntry: Identifiable, Codable {
    var id = UUID()
    var date = Date()
    var severity: Int = 5
    var triggers: String = ""
    var notes: String = ""
    var simulatorPresetName: String? = nil
}

// MARK: - Log Store

@Observable
class LogStore {
    var entries: [LogEntry] = []

    private let storageKey = "symptomLogEntries"

    init() {
        load()
    }

    func add(_ entry: LogEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            entries = try JSONDecoder().decode([LogEntry].self, from: data)
        } catch {
            print("LogStore: failed to decode entries — \(error.localizedDescription)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("LogStore: failed to encode entries — \(error.localizedDescription)")
        }
    }
}

// MARK: - Log View

struct LogView: View {
    @State private var store = LogStore()
    @State private var showingAddSheet = false

    var body: some View {
        Group {
            if store.entries.isEmpty {
                ContentUnavailableView(
                    "No Entries",
                    systemImage: "list.clipboard",
                    description: Text("Tap the button below to log your first entry.")
                )
            } else {
                List {
                    ForEach(store.entries) { entry in
                        LogEntryRow(entry: entry)
                    }
                    .onDelete { offsets in
                        store.delete(at: offsets)
                    }
                }
            }
        }
        .navigationTitle("Symptom Log")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add log entry")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEntrySheet(store: store)
        }
    }
}

// MARK: - Log Entry Row

private struct LogEntryRow: View {
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.date, style: .date)
                    .font(.subheadline.bold())
                Spacer()
                SeverityBadge(severity: entry.severity)
            }

            if !entry.triggers.isEmpty {
                Label(entry.triggers, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Triggers: \(entry.triggers)")
            }

            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .accessibilityLabel("Notes: \(entry.notes)")
            }

            if let presetName = entry.simulatorPresetName, !presetName.isEmpty {
                Label(presetName, systemImage: "sparkles.rectangle.stack")
                    .font(.caption2)
                    .foregroundStyle(.tint)
                    .accessibilityLabel("Simulator preset: \(presetName)")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Severity Badge

private struct SeverityBadge: View {
    let severity: Int

    private var color: Color {
        switch severity {
        case 1...3: return .green
        case 4...6: return .yellow
        case 7...8: return .orange
        default: return .red
        }
    }

    var body: some View {
        Text("\(severity)/10")
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2), in: Capsule())
            .foregroundStyle(color)
            .accessibilityLabel("Severity \(severity) out of 10")
    }
}

// MARK: - Add Entry Sheet

private struct AddEntrySheet: View {
    let store: LogStore
    @Environment(\.dismiss) private var dismiss

    @State private var severity: Double = 5
    @State private var triggers = ""
    @State private var notes = ""
    @State private var simulatorPresetName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    LabeledContent("Today", value: Date.now, format: .dateTime.month().day().year())
                }

                Section("Severity") {
                    VStack(alignment: .leading) {
                        Text("Severity: \(Int(severity))")
                        Slider(value: $severity, in: 1...10, step: 1)
                            .accessibilityLabel("Severity slider, \(Int(severity)) out of 10")
                    }
                }

                Section("Triggers") {
                    TextField("e.g. bright lights, screens, stress", text: $triggers)
                        .accessibilityLabel("Triggers text field")
                }

                Section("Notes") {
                    TextField("Additional notes…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Notes text field")
                }

                Section("Simulator Preset") {
                    TextField("Preset name (optional)", text: $simulatorPresetName)
                        .accessibilityLabel("Simulator preset name, optional")
                }
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel adding entry")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let entry = LogEntry(
                            severity: Int(severity),
                            triggers: triggers,
                            notes: notes,
                            simulatorPresetName: simulatorPresetName.isEmpty ? nil : simulatorPresetName
                        )
                        store.add(entry)
                        dismiss()
                    }
                    .accessibilityLabel("Save log entry")
                }
            }
        }
    }
}
