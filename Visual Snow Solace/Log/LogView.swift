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
                    NSLocalizedString("log.empty.title", comment: "Empty log title"),
                    systemImage: "list.clipboard",
                    description: Text(NSLocalizedString("log.empty.description", comment: "Empty log description"))
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
        .navigationTitle(NSLocalizedString("log.title", comment: "Symptom Log navigation title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(NSLocalizedString("log.addEntry.accessibility", comment: "Add entry button accessibility"))
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
                    .accessibilityLabel(String(format: NSLocalizedString("log.triggers.accessibility", comment: "Triggers accessibility"), entry.triggers))
            }

            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .accessibilityLabel(String(format: NSLocalizedString("log.notes.accessibility", comment: "Notes accessibility"), entry.notes))
            }

            if let presetName = entry.simulatorPresetName, !presetName.isEmpty {
                Label(presetName, systemImage: "sparkles.rectangle.stack")
                    .font(.caption2)
                    .foregroundStyle(.tint)
                    .accessibilityLabel(String(format: NSLocalizedString("log.simulatorPreset.accessibility", comment: "Simulator preset accessibility"), presetName))
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
        Text(String(format: NSLocalizedString("log.severity.badge", comment: "Severity badge format"), severity))
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2), in: Capsule())
            .foregroundStyle(color)
            .accessibilityLabel(String(format: NSLocalizedString("log.severity.accessibility", comment: "Severity accessibility"), severity))
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
                Section(NSLocalizedString("log.newEntry.date", comment: "Date section header")) {
                    LabeledContent(NSLocalizedString("log.newEntry.today", comment: "Today label"), value: Date.now, format: .dateTime.month().day().year())
                }

                Section(NSLocalizedString("log.newEntry.severity", comment: "Severity section header")) {
                    VStack(alignment: .leading) {
                        Text(String(format: NSLocalizedString("log.newEntry.severityValue", comment: "Severity value label"), Int(severity)))
                        Slider(value: $severity, in: 1...10, step: 1)
                            .accessibilityLabel(String(format: NSLocalizedString("log.newEntry.severitySlider.accessibility", comment: "Severity slider accessibility"), Int(severity)))
                    }
                }

                Section(NSLocalizedString("log.newEntry.triggers", comment: "Triggers section header")) {
                    TextField(NSLocalizedString("log.newEntry.triggers.placeholder", comment: "Triggers placeholder"), text: $triggers)
                        .accessibilityLabel(NSLocalizedString("log.newEntry.triggers.accessibility", comment: "Triggers field accessibility"))
                }

                Section(NSLocalizedString("log.newEntry.notes", comment: "Notes section header")) {
                    TextField(NSLocalizedString("log.newEntry.notes.placeholder", comment: "Notes placeholder"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel(NSLocalizedString("log.newEntry.notes.accessibility", comment: "Notes field accessibility"))
                }

                Section(NSLocalizedString("log.newEntry.simulatorPreset", comment: "Simulator Preset section header")) {
                    TextField(NSLocalizedString("log.newEntry.simulatorPreset.placeholder", comment: "Simulator preset placeholder"), text: $simulatorPresetName)
                        .accessibilityLabel(NSLocalizedString("log.newEntry.simulatorPreset.accessibility", comment: "Simulator preset field accessibility"))
                }
            }
            .navigationTitle(NSLocalizedString("log.newEntry.title", comment: "New Entry navigation title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("log.newEntry.cancel", comment: "Cancel button")) { dismiss() }
                        .accessibilityLabel(NSLocalizedString("log.newEntry.cancel.accessibility", comment: "Cancel button accessibility"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("log.newEntry.save", comment: "Save button")) {
                        let entry = LogEntry(
                            severity: Int(severity),
                            triggers: triggers,
                            notes: notes,
                            simulatorPresetName: simulatorPresetName.isEmpty ? nil : simulatorPresetName
                        )
                        store.add(entry)
                        dismiss()
                    }
                    .accessibilityLabel(NSLocalizedString("log.newEntry.save.accessibility", comment: "Save button accessibility"))
                }
            }
        }
    }
}
