import SwiftUI

// MARK: - Root Dashboard

struct DashboardView: View {
    @StateObject private var viewModel = AppViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                mobileLayout
            } else {
                desktopLayout
            }
        }
        .environmentObject(viewModel)
        .background(Color(.systemBackground))
    }

    private var desktopLayout: some View {
        HStack(spacing: 0) {
            GoalMenuView()
                .frame(minWidth: 240, maxWidth: 260)
                .background(Color(.secondarySystemBackground))

            Divider()

            TimeBlockCalendarView()
                .frame(minWidth: 320)

            Divider()

            TodoListView()
                .frame(minWidth: 260, maxWidth: 320)
                .background(Color(.secondarySystemBackground))
        }
    }

    private var mobileLayout: some View {
        TabView {
            GoalMindMapScreen()
                .tabItem {
                    Label("Goals", systemImage: "tree")
                }
            TimeBlockCalendarView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
            TodoListView()
                .tabItem {
                    Label("To‑Dos", systemImage: "checklist")
                }
            JournalScreen()
                .tabItem {
                    Label("Journal", systemImage: "text.book.closed")
                }
        }
    }
}

// MARK: - Goal Mind Map

struct GoalMindMapScreen: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedNode: GoalNode?
    @State private var zoomScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                GeometryReader { proxy in
                    mindMapBody(in: proxy.size)
                }
                .frame(height: 600)
            }

            if let node = selectedNode {
                NodeDetailPanel(node: node, isPresented: Binding(
                    get: { selectedNode != nil },
                    set: { newValue in if !newValue { selectedNode = nil } }
                ))
            }
        }
        .navigationTitle("Future Self")
    }

    private func mindMapBody(in size: CGSize) -> some View {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        return ZStack {
            // Simple radial layout placeholder. A full implementation would support drag, drop, expand / collapse, etc.
            goalNodeView(viewModel.rootGoal, at: center, depth: 0)
        }
        .scaleEffect(zoomScale)
        .offset(offset)
        .gesture(MagnificationGesture()
            .onChanged { value in zoomScale = value }
        )
        .gesture(DragGesture()
            .onChanged { value in offset = value.translation }
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: zoomScale)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: offset)
    }

    private func goalNodeView(_ node: GoalNode, at center: CGPoint, depth: Int) -> some View {
        VStack {
            Button {
                selectedNode = node
            } label: {
                Text(node.title)
                    .font(depth == 0 ? .headline : .subheadline)
                    .padding(8)
                    .background(node.level.color.opacity(0.15))
                    .foregroundColor(.primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(node.level.color, lineWidth: depth == 0 ? 2 : 1)
                    )
                    .cornerRadius(12)
            }

            if !node.children.isEmpty {
                ForEach(node.children, id: \.id) { child in
                    goalNodeView(child, at: center, depth: depth + 1)
                        .padding(.top, 8)
                }
            }
        }
        .position(center)
    }
}

// MARK: - Goal Menu (Tree)

struct GoalMenuView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var expanded: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List {
                Section("Goals") {
                    goalRow(viewModel.rootGoal, indent: 0)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Goals")
        }
    }

    private func goalRow(_ node: GoalNode, indent: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if !node.children.isEmpty {
                    Button {
                        toggle(node)
                    } label: {
                        Image(systemName: expanded.contains(node.id) ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 4))
                        .foregroundColor(.secondary)
                        .frame(width: 16)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(node.title)
                        .font(.subheadline)
                    Text(node.level.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.leading, indent)

            if expanded.contains(node.id) {
                ForEach(node.children, id: \.id) { child in
                    goalRow(child, indent: indent + 16)
                }
            }
        }
    }

    private func toggle(_ node: GoalNode) {
        if expanded.contains(node.id) {
            expanded.remove(node.id)
        } else {
            expanded.insert(node.id)
        }
    }
}

// MARK: - Time‑Block Calendar (Simplified Hourly View)

struct TimeBlockCalendarView: View {
    @EnvironmentObject var viewModel: AppViewModel
    private let hours = Array(6...22)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Today")
                    .font(.headline)
                Spacer()
            }
            .padding()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(hours, id: \.self) { hour in
                        HourRow(hour: hour, tasks: tasks(atHour: hour))
                    }
                }
            }
        }
    }

    private func tasks(atHour hour: Int) -> [TaskItem] {
        let calendar = Calendar.current
        return viewModel.tasks.filter { task in
            guard let start = task.scheduledStart else { return false }
            return calendar.component(.hour, from: start) == hour
        }
    }
}

private struct HourRow: View {
    let hour: Int
    let tasks: [TaskItem]

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(String(format: "%02d:00", hour))
                .font(.caption)
                .frame(width: 52, alignment: .trailing)
                .padding(.top, 8)

            Rectangle()
                .fill(Color(.separator))
                .frame(width: 1)

            VStack(alignment: .leading, spacing: 4) {
                if tasks.isEmpty {
                    Text("Free")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 6)
                } else {
                    ForEach(tasks) { task in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.subheadline)
                                Text("\(task.durationMinutes) min")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(8)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
        .frame(height: 52)
    }
}

// MARK: - To‑Do List

struct TodoListView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.tasks) { task in
                    HStack {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.isCompleted ? .green : .secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                            Text("\(task.durationMinutes) min")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("To‑Dos")
        }
    }
}

// MARK: - Journaling

struct JournalScreen: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var text: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextEditor(text: $text)
                    .padding()
                    .background(Color(.systemBackground))

                Button(action: saveEntry) {
                    Text("Save Entry")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.4) : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding()
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .navigationTitle("Journal")
        }
    }

    private func saveEntry() {
        let entry = JournalEntry(
            id: UUID(),
            createdAt: Date(),
            text: text,
            dominantMoods: [] // Placeholder for AI tagging
        )
        viewModel.journalEntries.insert(entry, at: 0)
        text = ""
    }
}

// MARK: - Node Editor Panel (Placeholder)

struct NodeDetailPanel: View {
    let node: GoalNode
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(node.title)
                        .font(.headline)
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                }

                Text(node.description.isEmpty ? "No description yet." : node.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Level: \(node.level.displayName)")
                    .font(.caption)

                HStack {
                    Text("Priority: \(node.priority)")
                        .font(.caption)
                    Spacer()
                    if let date = node.targetDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Material.regular)
            .cornerRadius(16, corners: [.topLeft, .topRight])
        }
        .ignoresSafeArea(edges: .bottom)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Corner Radius Helper

private struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}


