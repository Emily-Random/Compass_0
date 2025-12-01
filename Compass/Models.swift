import Foundation
import SwiftUI

// MARK: - Goal Hierarchy

enum GoalLevel: String, Codable, CaseIterable, Identifiable {
    case futureSelf
    case lifetime
    case yearly
    case monthly
    case weekly
    case daily

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .futureSelf: return "Future Self"
        case .lifetime: return "Lifetime"
        case .yearly: return "Yearly"
        case .monthly: return "Monthly"
        case .weekly: return "Weekly"
        case .daily: return "Daily"
        }
    }

    var color: Color {
        switch self {
        case .futureSelf: return .blue
        case .lifetime: return .purple
        case .yearly: return .indigo
        case .monthly: return .teal
        case .weekly: return .orange
        case .daily: return .green
        }
    }
}

struct GoalNode: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var priority: Int
    var targetDate: Date?
    var level: GoalLevel
    var children: [GoalNode]

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        priority: Int = 3,
        targetDate: Date? = nil,
        level: GoalLevel,
        children: [GoalNode] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.targetDate = targetDate
        self.level = level
        self.children = children
    }
}

// MARK: - Tasks & Scheduling

struct TaskItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var goalId: UUID?
    var durationMinutes: Int
    var scheduledStart: Date?
    var scheduledEnd: Date? {
        guard let start = scheduledStart else { return nil }
        return Calendar.current.date(byAdding: .minute, value: durationMinutes, to: start)
    }
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        title: String,
        goalId: UUID? = nil,
        durationMinutes: Int = 60,
        scheduledStart: Date? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.goalId = goalId
        self.durationMinutes = durationMinutes
        self.scheduledStart = scheduledStart
        self.isCompleted = isCompleted
    }
}

// Optional higher-level calendar block type if needed later.
struct CalendarBlock: Identifiable, Hashable {
    let id: UUID
    var task: TaskItem
    var start: Date
    var end: Date
}

// MARK: - Journaling

struct JournalEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: Date
    var text: String
    // Mood is a coarse self-report; richer modeling happens server-side.
    var moodScore: Int? // -3 (very low) ... 0 (neutral) ... +3 (very positive)

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        text: String = "",
        moodScore: Int? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
        self.moodScore = moodScore
    }
}

// MARK: - Reflection Summaries

struct WeeklySummary: Identifiable, Codable {
    let id: UUID
    let weekStart: Date
    let themes: [String]
    let highPoints: [String]
    let motivations: [String]
    let avoidancePatterns: [String]
}

struct MonthlyReflection: Identifiable, Codable {
    let id: UUID
    let monthStart: Date
    let goalPriorityAdjustments: [UUID: Int] // goalId -> new priority
    let notes: String
}

