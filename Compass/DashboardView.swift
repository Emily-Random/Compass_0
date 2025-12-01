import SwiftUI

enum MainTab: Hashable {
    case dashboard
    case goals
    case journal
    case reflections
}

struct DashboardView: View {
    @State private var selectedTab: MainTab = .dashboard

    // In a real app these would be provided by an ObservableObject
    // backed by the backend API.
    @State private var rootGoal = GoalNode(
        title: "Future Self",
        description: "High-context, long-term direction.",
        level: .futureSelf,
        children: [
            GoalNode(
                title: "Deep Work Career",
                level: .lifetime,
                children: [
                    GoalNode(title: "AI Research Portfolio", level: .yearly),
                    GoalNode(title: "Writing Habit", level: .yearly)
                ]
            )
        ]
    )

    @State private var tasks: [TaskItem] = [
        TaskItem(title: "Write research summary", durationMinutes: 90),
        TaskItem(title: "Deep work block – coding", durationMinutes: 120),
        TaskItem(title: "Admin: email triage", durationMinutes: 30)
    ]

    @State private var journalEntries: [JournalEntry] = []

    var body: some View {
        NavigationStack {
            Group {
                switch selectedTab {
                case .dashboard:
                    AdaptiveDashboardLayout(
                        rootGoal: $rootGoal,
                        tasks: $tasks
                    )
                case .goals:
                    MindMapScreen(rootGoal: $rootGoal)
                case .journal:
                    JournalScreen(entries: $journalEntries)
                case .reflections:
                    ReflectionScreen()
                }
            }
            .navigationTitle(title(for: selectedTab))
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Picker("Section", selection: $selectedTab) {
                        Label("Dashboard", systemImage: "rectangle.split.3x1")
                            .tag(MainTab.dashboard)
                        Label("Goals", systemImage: "circles.hexagongrid")
                            .tag(MainTab.goals)
                        Label("Journal", systemImage: "square.and.pencil")
                            .tag(MainTab.journal)
                        Label("Reflect", systemImage: "chart.bar.doc.horizontal")
                            .tag(MainTab.reflections)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    private func title(for tab: MainTab) -> String {
        switch tab {
        case .dashboard: return "Compass"
        case .goals: return "Goals – Future Self Map"
        case .journal: return "Journaling"
        case .reflections: return "Reflection"
        }
    }
}

// MARK: - Dashboard Columns

struct AdaptiveDashboardLayout: View {
    @Binding var rootGoal: GoalNode
    @Binding var tasks: [TaskItem]

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            // Laptop / iPad style – three columns
            HStack(spacing: 0) {
                GoalTreePane(rootGoal: $rootGoal)
                    .frame(minWidth: 220, maxWidth: 280)
                    .background(.background)
                    .overlay(Divider(), alignment: .trailing)

                CalendarPane(tasks: $tasks)
                    .frame(minWidth: 320)
                    .overlay(Divider(), alignment: .trailing)

                ToDoPane(tasks: $tasks)
                    .frame(minWidth: 220, maxWidth: 280)
            }
        } else {
            // iPhone – stacked
            ScrollView {
                VStack(spacing: 16) {
                    GoalTreePane(rootGoal: $rootGoal)
                    CalendarPane(tasks: $tasks)
                    ToDoPane(tasks: $tasks)
                }
                .padding()
            }
        }
    }
}

// Left: Goal Menu
struct GoalTreePane: View {
    @Binding var rootGoal: GoalNode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Goals")
                .font(.headline)
            List {
                GoalTreeRow(node: rootGoal, level: 0)
            }
            .listStyle(.plain)
        }
        .padding()
    }
}

struct GoalTreeRow: View {
    let node: GoalNode
    let level: Int
    @State private var isExpanded: Bool = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(node.children, id: \.id) { child in
                GoalTreeRow(node: child, level: level + 1)
            }
        } label: {
            HStack {
                Circle()
                    .fill(color(for: node.level))
                    .frame(width: 8, height: 8)
                Text(node.title)
                    .font(.subheadline)
                Spacer()
            }
        }
    }

    private func color(for level: GoalLevel) -> Color {
        switch level {
        case .futureSelf: return .blue
        case .lifetime: return .purple
        case .yearly: return .indigo
        case .monthly: return .teal
        case .weekly: return .orange
        case .daily: return .green
        }
    }
}

// Center: Time-blocked Calendar (simplified hour grid)
struct CalendarPane: View {
    @Binding var tasks: [TaskItem]

    private let hours = Array(6...22)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.headline)
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(hours, id: \.self) { hour in
                        HStack(alignment: .top, spacing: 8) {
                            Text(String(format: "%02d:00", hour))
                                .font(.caption)
                                .frame(width: 50, alignment: .trailing)

                            Rectangle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 48)
                                .overlay(alignment: .topLeading) {
                                    // Simple: show first matching task title
                                    if let task = tasks.first {
                                        Text(task.title)
                                            .font(.caption)
                                            .padding(6)
                                    }
                                }
                        }
                        .padding(.vertical, 2)
                        Divider()
                    }
                }
            }
        }
        .padding()
    }
}

// Right: To‑Do List
struct ToDoPane: View {
    @Binding var tasks: [TaskItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("To‑Do")
                .font(.headline)
            List {
                ForEach(tasks) { task in
                    HStack {
                        Button {
                            toggle(task)
                        } label: {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(task.isCompleted ? .green : .secondary)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .strikethrough(task.isCompleted, color: .secondary)
                            Text("\(task.durationMinutes) min")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
            }
            .listStyle(.plain)
        }
        .padding()
    }

    private func toggle(_ task: TaskItem) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isCompleted.toggle()
        }
    }
}

// MARK: - Mind Map + Journal + Reflection Screens

struct MindMapScreen: View {
    @Binding var rootGoal: GoalNode

    var body: some View {
        MindMapView(rootGoal: $rootGoal)
            .padding()
    }
}

struct JournalScreen: View {
    @Binding var entries: [JournalEntry]
    @State private var draftText: String = ""

    var body: some View {
        VStack(spacing: 12) {
            TextEditor(text: $draftText)
                .frame(minHeight: 200)
                .padding(8)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("Free‑write journal editor")

            HStack {
                Spacer()
                Button("Save Entry") {
                    let entry = JournalEntry(text: draftText)
                    entries.insert(entry, at: 0)
                    draftText = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            List {
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(entry.text)
                            .font(.body)
                            .lineLimit(3)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
        }
        .padding()
    }
}

struct ReflectionScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly Summary")
                        .font(.headline)
                    // Placeholder visualization
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .frame(height: 140)
                        .overlay {
                            Text("Stacked bars: hours spent per goal cluster")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding()
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Themes from Journals")
                        .font(.headline)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 120)
                        .overlay {
                            Text("Word themes and emotional patterns")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding()
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Goal Progress")
                        .font(.headline)
                    VStack(spacing: 12) {
                        ProgressView("Deep Work", value: 0.4)
                        ProgressView("Health", value: 0.6)
                        ProgressView("Relationships", value: 0.3)
                    }
                }
            }
            .padding()
        }
    }
}


