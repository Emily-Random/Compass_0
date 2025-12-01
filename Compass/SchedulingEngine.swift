import Foundation

/// High-level description of procrastination-aware scheduling behavior.
///
/// The full implementation will live on the backend so that
/// cross-platform clients share a single source of truth.
/// This Swift type documents the expected contract and can be
/// used to stub local previews or offline behavior.
struct SchedulingSuggestion: Identifiable {
    let id = UUID()
    let task: TaskItem
    let proposedStart: Date
    let reason: String
}

protocol SchedulingEngineProtocol {
    /// Given a set of tasks, existing calendar blocks, and recent mood/behavior logs,
    /// return suggested time-blocks, possibly splitting tasks into smaller units.
    func suggestSchedule(
        tasks: [TaskItem],
        existingEvents: [DateInterval],
        moodSamples: [Int], // coarse aggregate for now; full model is backend-driven
        now: Date
    ) -> [SchedulingSuggestion]
}

/// Minimal local stub that captures the *shape* of the logic.
/// Real intelligence is server-side (FastAPI / Node / etc.).
final class LocalSchedulingEngineStub: SchedulingEngineProtocol {
    func suggestSchedule(
        tasks: [TaskItem],
        existingEvents: [DateInterval],
        moodSamples: [Int],
        now: Date
    ) -> [SchedulingSuggestion] {
        // Pseudocode of the true engine:
        //
        // 1. Learn user "weak" and "strong" hours from past completions.
        // 2. Detect avoidance patterns per task type (hard / creative / admin).
        // 3. Use journaling-derived mood time series to label:
        //    - burnout windows
        //    - recovery windows
        //    - high-focus windows
        // 4. If a task is repeatedly skipped:
        //    - break into smaller chunks
        //    - schedule in strong windows
        //    - add low-friction lead‑in tasks if needed.
        // 5. Respect user’s connected calendars and weekly template.
        //
        // For now, we just place tasks sequentially after `now`
        // in the first free gaps that are at least `durationMinutes` long.

        var suggestions: [SchedulingSuggestion] = []
        var cursor = now

        func isFree(_ interval: DateInterval) -> Bool {
            !existingEvents.contains { event in
                event.intersects(interval)
            }
        }

        for task in tasks where !task.isCompleted {
            let duration = TimeInterval(task.durationMinutes * 60)

            // Naive search forward in 15-minute increments.
            var proposedStart = cursor
            var iterations = 0
            while iterations < 7 * 24 * 4 { // search up to ~1 week ahead
                let block = DateInterval(start: proposedStart, duration: duration)
                if isFree(block) {
                    let suggestion = SchedulingSuggestion(
                        task: task,
                        proposedStart: proposedStart,
                        reason: "Next available free block"
                    )
                    suggestions.append(suggestion)
                    cursor = block.end
                    break
                }
                proposedStart = proposedStart.addingTimeInterval(15 * 60)
                iterations += 1
            }
        }

        return suggestions
    }
}


