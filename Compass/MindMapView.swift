import SwiftUI

/// Minimal, non-gamified mind‑map view.
/// This is intentionally serious and calm: no points, streaks, or badges.
struct MindMapView: View {
    @Binding var rootGoal: GoalNode

    @State private var selectedNode: GoalNode?
    @State private var zoom: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            GeometryReader { proxy in
                ScrollView([.horizontal, .vertical]) {
                    Canvas { context, size in
                        let center = CGPoint(x: size.width / 2 + offset.width,
                                             y: size.height / 2 + offset.height)
                        drawNode(
                            node: rootGoal,
                            at: center,
                            depth: 0,
                            in: &context
                        )
                    }
                    .frame(width: proxy.size.width * 2, height: proxy.size.height * 2)
                    .scaleEffect(zoom)
                    .gesture(mindMapGestures)
                }
            }

            if let selected = selectedNode {
                NodeEditor(node: selected) { updated in
                    updateNode(updated)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }

    private var mindMapGestures: some Gesture {
        SimultaneousGesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation
                },
            MagnificationGesture()
                .onChanged { value in
                    zoom = min(max(0.5, value), 2.0)
                }
        )
    }

    // Simplified radial layout: children are drawn in a circle around parent.
    private func drawNode(
        node: GoalNode,
        at position: CGPoint,
        depth: Int,
        in context: inout GraphicsContext
    ) {
        let nodeRadius: CGFloat = 60
        let circle = Path(ellipseIn: CGRect(
            x: position.x - nodeRadius,
            y: position.y - nodeRadius,
            width: nodeRadius * 2,
            height: nodeRadius * 2
        ))

        var style = GraphicsContext.Shading.color(color(for: node.level))
        context.fill(circle, with: style)

        // Node title
        let text = Text(node.title)
            .font(depth == 0 ? .headline : .subheadline)
            .foregroundColor(.white)
        context.draw(text, at: position, anchor: .center)

        // Draw children in a ring
        let childCount = node.children.count
        guard childCount > 0 else { return }

        let radius: CGFloat = 150 + CGFloat(depth) * 40
        for (index, child) in node.children.enumerated() {
            let angle = (Double(index) / Double(childCount)) * 2 * Double.pi
            let childPosition = CGPoint(
                x: position.x + cos(angle) * radius,
                y: position.y + sin(angle) * radius
            )

            // Edge
            var path = Path()
            path.move(to: position)
            path.addLine(to: childPosition)
            context.stroke(path, with: .color(.secondary), lineWidth: 1)

            drawNode(
                node: child,
                at: childPosition,
                depth: depth + 1,
                in: &context
            )
        }
    }

    private func color(for level: GoalLevel) -> Color {
        switch level {
        case .futureSelf: return .blue.opacity(0.8)
        case .lifetime: return .purple.opacity(0.8)
        case .yearly: return .indigo.opacity(0.8)
        case .monthly: return .teal.opacity(0.8)
        case .weekly: return .orange.opacity(0.8)
        case .daily: return .green.opacity(0.8)
        }
    }

    private func updateNode(_ updated: GoalNode) {
        func recurse(_ node: inout GoalNode) {
            if node.id == updated.id {
                node = updated
                return
            }
            for idx in node.children.indices {
                recurse(&node.children[idx])
            }
        }
        recurse(&rootGoal)
        selectedNode = nil
    }
}

// MARK: - Node Editor Panel

struct NodeEditor: View {
    @State private var draft: GoalNode
    var onSave: (GoalNode) -> Void

    @Environment(\.dismiss) private var dismiss

    init(node: GoalNode, onSave: @escaping (GoalNode) -> Void) {
        _draft = State(initialValue: node)
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Edit Goal")
                    .font(.headline)
                Spacer()
            }

            TextField("Title", text: $draft.title)
                .textFieldStyle(.roundedBorder)

            TextField("Description", text: $draft.description, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3, reservesSpace: true)

            HStack {
                Text("Priority")
                Spacer()
                Stepper(value: $draft.priority, in: 1...5) {
                    Text("\(draft.priority)")
                }
                .frame(width: 140)
            }

            DatePicker("Target Date", selection: Binding(
                get: { draft.targetDate ?? Date() },
                set: { draft.targetDate = $0 }
            ), displayedComponents: .date)

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
                    onSave(draft)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: 360)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .padding()
        .accessibilityElement(children: .contain)
    }
}


