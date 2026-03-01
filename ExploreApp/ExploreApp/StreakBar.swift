//
//  MainView.swift
//  ExploreApp
//

import SwiftUI
import Foundation
import Combine

// MARK: - Models

enum DayStatus {
    case alive      // streak kept
    case missed     // streak was missed
    case future     // upcoming days
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
    
    private var realCurrentWeekStart: Date {
        calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        )!
    }
    
    private let calendar = Calendar.current
    @Published var currentWeekStart: Date = Calendar.current.startOfDay(for: Date())
    
    private let firstUseKey = "firstUseDate"

    private var firstUseDate: Date {
        if let stored = UserDefaults.standard.object(forKey: firstUseKey) as? Date {
            return stored
        } else {
            let now = Calendar.current.startOfDay(for: Date())
            UserDefaults.standard.set(now, forKey: firstUseKey)
            return now
        }
    }
    
    var firstAllowedWeekStart: Date {
        calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: firstUseDate)
        )!
    }
    
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
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentWeekStart)) else {
            return []
        }
        
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: weekStart)!
            let status: DayStatus
            
            if let last = lastValidDay {
                if calendar.isDate(day, inSameDayAs: last) || day < last {
                    if missedDay != nil && calendar.isDate(day, inSameDayAs: missedDay!) {
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
        
        // Block going earlier than first app use week
        if previous >= firstAllowedWeekStart {
            currentWeekStart = previous
        }
    }
    
    func nextWeek() {
        let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart)!
        
        // Block scrolling into future weeks
        if nextWeek <= realCurrentWeekStart {
            currentWeekStart = nextWeek
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
                .disabled(
                    streakManager.currentWeekStart <= streakManager.firstAllowedWeekStart
                )
                .opacity(
                    streakManager.currentWeekStart <= streakManager.firstAllowedWeekStart ? 0.4 : 1.0
                )
                
                Spacer()
                
                Button(action: { streakManager.nextWeek() }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .padding()
                        .foregroundColor(
                            streakManager.currentWeekStart < Calendar.current.date(
                                from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
                            )!
                            ? .blue
                            : .gray
                        )
                }
                .disabled(
                    streakManager.currentWeekStart >= Calendar.current.date(
                        from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
                    )!
                )
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
                            .fill(circleColor(for: day.status))
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
        .edgesIgnoringSafeArea(.top)
    }
    
    private func circleColor(for status: DayStatus) -> Color {
        switch status {
        case .alive:
            return .green
        case .missed:
            return .yellow
        case .future:
            // Check if the previous day was missed and the user did not explore new tile
            if let last = streakManager.lastValidDay, let missed = streakManager.missedDay {
                let calendar = Calendar.current
                let daysSinceMissed = calendar.dateComponents([.day], from: missed, to: last).day ?? 0
                if daysSinceMissed == 1 {
                    // User did not explore new tile after missed day
                    return .red
                }
            }
            return .gray
        }
    }
}

// MARK: - Main View

struct StreakBar: View {
    @StateObject var streakManager = StreakManager()
    
    var body: some View {
        VStack(spacing: 0) {
            StreakBarView(streakManager: streakManager) // pinned at top
        }
    }
}

// MARK: - Preview

#Preview {
    StreakBar()
}
