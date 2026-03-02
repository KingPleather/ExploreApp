//
//  MainView.swift
//  ExploreApp
//

import SwiftUI
import Foundation
import Combine

// MARK: - Models

enum DayStatus {
    case alive
    case missed
    case future
}

struct StreakDay: Identifiable {
    let id = UUID()
    let date: Date
    let status: DayStatus
}

enum ExplorationAction {
    case newTile
    case revisitOutsideHome
}

// MARK: - Streak Manager

class StreakManager: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var lastValidDay: Date?
    @Published var missedDay: Date?
    
    private let calendar = Calendar.current
    
    // MARK: Testing overrides
    var testingMode = false
    var overrideFirstAllowedWeekStart: Date?
    var overrideRealCurrentWeekStart: Date?
    
    private var realCurrentWeekStartInternal: Date {
        calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        )!
    }
    
    var realCurrentWeekStart: Date {
        testingMode ? (overrideRealCurrentWeekStart ?? realCurrentWeekStartInternal)
                    : realCurrentWeekStartInternal
    }
    
    @Published var currentWeekStart: Date = Calendar.current.startOfDay(for: Date())
    
    private let firstUseKey = "firstUseDate"

    private var firstUseDateInternal: Date {
        if let stored = UserDefaults.standard.object(forKey: firstUseKey) as? Date {
            return stored
        } else {
            let now = Calendar.current.startOfDay(for: Date())
            UserDefaults.standard.set(now, forKey: firstUseKey)
            return now
        }
    }
    
    var firstAllowedWeekStart: Date {
        if testingMode, let override = overrideFirstAllowedWeekStart {
            return override
        }
        return calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: firstUseDateInternal)
        )!
    }
    
    // MARK: Streak Logic
    
    func logAction(_ action: ExplorationAction, date: Date = Date()) {
        let today = calendar.startOfDay(for: date)
        
        guard let lastDay = lastValidDay else {
            currentStreak = 1
            lastValidDay = today
            return
        }
        
        let daysSinceLast = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
        
        switch daysSinceLast {
        case 0:
            return
        case 1:
            currentStreak += 1
            lastValidDay = today
            missedDay = nil
        case 2:
            if action == .newTile {
                currentStreak += 1
                lastValidDay = today
                missedDay = nil
            } else {
                resetStreak(today)
            }
        default:
            resetStreak(today)
        }
    }
    
    private func resetStreak(_ today: Date) {
        currentStreak = 1
        lastValidDay = today
        missedDay = nil
    }
    
    func weekDates() -> [StreakDay] {
        guard let weekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentWeekStart)
        ) else {
            return []
        }
        
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: weekStart)!
            let status: DayStatus
            
            if let last = lastValidDay {
                if calendar.isDate(day, inSameDayAs: last) || day < last {
                    if let missed = missedDay, calendar.isDate(day, inSameDayAs: missed) {
                        status = .missed
                    } else {
                        status = .alive
                    }
                } else {
                    status = .future
                }
            } else {
                status = .future
            }
            
            return StreakDay(date: day, status: status)
        }
    }
    
    func previousWeek() {
        let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)!
        if previous >= firstAllowedWeekStart {
            currentWeekStart = previous
        }
    }
    
    func nextWeek() {
        let next = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart)!
        if next <= realCurrentWeekStart {
            currentWeekStart = next
        }
    }
}

// MARK: - Streak Bar UI

struct StreakBarView: View {
    @ObservedObject var streakManager: StreakManager
    
    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "E"
        return f
    }()
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { streakManager.previousWeek() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .padding()
                        .foregroundColor(
                            streakManager.currentWeekStart > streakManager.firstAllowedWeekStart
                            ? .blue
                            : .gray
                        )
                }
                .disabled(streakManager.currentWeekStart <= streakManager.firstAllowedWeekStart)
                .opacity(streakManager.currentWeekStart <= streakManager.firstAllowedWeekStart ? 0.4 : 1)
                
                Spacer()
                
                Button(action: { streakManager.nextWeek() }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .padding()
                        .foregroundColor(
                            streakManager.currentWeekStart < streakManager.realCurrentWeekStart
                            ? .blue
                            : .gray
                        )
                }
                .disabled(streakManager.currentWeekStart >= streakManager.realCurrentWeekStart)
            }
            
            if let firstDay = streakManager.weekDates().first {
                let year = Calendar.current.component(.year, from: firstDay.date)
                Text(String(year))
                    .font(.headline)
                    .padding(.bottom, 4)
            }
            
            HStack(spacing: 12) {
                ForEach(streakManager.weekDates()) { day in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(circleColor(for: day.status, day: day))
                            .frame(width: 30, height: 30)
                        
                        Text(dayFormatter.string(from: day.date))
                            .font(.caption2)
                        
                        Text(dateFormatter.string(from: day.date))
                            .font(.caption2)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private func circleColor(for status: DayStatus, day: StreakDay) -> Color {
        let calendar = Calendar.current

        // RED = the day immediately after the missed day
        if let missed = streakManager.missedDay,
           let warningDay = calendar.date(byAdding: .day, value: 1, to: missed),
           calendar.isDate(day.date, inSameDayAs: warningDay) {
            return .red
        }

        switch status {
        case .alive:
            return .green
        case .missed:
            return .yellow
        case .future:
            return .gray
        }
    }
}

// MARK: - Main View

struct StreakBar: View {
    @StateObject var streakManager = StreakManager()
    
    var body: some View {
        StreakBarView(streakManager: streakManager)
    }
}

// MARK: - Preview

#Preview {
    UserDefaults.standard.removeObject(forKey: "firstUseDate")

    let manager = StreakManager()
    let calendar = Calendar.current

    manager.testingMode = true

    let fakeToday = calendar.date(from: DateComponents(year: 2025, month: 1, day: 5))!

    manager.overrideRealCurrentWeekStart = fakeToday
    manager.overrideFirstAllowedWeekStart = calendar.date(byAdding: .weekOfYear, value: -10, to: fakeToday)!

    manager.currentWeekStart = fakeToday

    let sunday = fakeToday
    let tuesday = calendar.date(byAdding: .day, value: 2, to: sunday)!
    let wednesday = calendar.date(byAdding: .day, value: 4, to: sunday)!

    manager.missedDay = tuesday
    manager.lastValidDay = wednesday
    manager.currentStreak = 6

    return StreakBar(streakManager: manager)
}
