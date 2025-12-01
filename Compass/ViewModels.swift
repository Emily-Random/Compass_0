import Foundation
import SwiftUI

/// Root application view model placeholder.
/// In a real implementation this would be backed by a shared backend and AI models.
final class AppViewModel: ObservableObject {
    @Published var rootGoal: GoalNode
    @Published var tasks: [TaskItem]
    @Published var journalEntries: [JournalEntry]

    init() {
        // Seed with a "Future Self" root goal and a few sample children for demo purposes.
        let daily = GoalNode(title: "Today: Focused Deep Work", level: .daily)
        let weekly = GoalNode(title: "This Week: Ship Milestone", level: .weekly, children: [daily])
        let yearly = GoalNode(title: "Year: Advance Career", level: .yearly, children: [weekly])
        self.rootGoal = GoalNode(
            title: "Future Self",
            description: "Long‑term direction of your life.",
            priority: 5,
            targetDate: nil,
            level: .lifetime,
            children: [yearly]
        )

        self.tasks = [
            TaskItem(title: "Deep work: write strategy doc", durationMinutes: 90),
            TaskItem(title: "Review long‑term goals", durationMinutes: 45),
            TaskItem(title: "Process inbox", durationMinutes: 30, isFlexible: true)
        ]

        self.journalEntries = []
    }
}


