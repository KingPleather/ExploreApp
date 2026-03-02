//
//  SummaryView.swift
//  ExploreApp
//
//  Created by Jono Tan on 3/1/26.
//

import SwiftUI
import Charts

// MARK: - EXPLORATION PROGRESS VIEW
struct ExplorationProgressView: View {
    let dailyStats: DailyExplorationStats
    let streakStats: ExplorationStreakStats
    let explorationScore: ExplorationScore
    
    var body: some View {
        VStack(spacing: 24) {
            
            // MARK: - Daily Exploration
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Exploration")
                    .font(.headline)
                
                HStack {
                    StatBox(
                        title: "Steps Today",
                        value: "\(dailyStats.stepsToday)"
                    )
                    StatBox(
                        title: "Home Bubble",
                        value: dailyStats.leftHomeBubble ? "Went out!" : "Stayed In"
                    )
                    StatBox(
                        title: "Islands Unlocked",
                        value: "\(dailyStats.islandsUnlockedToday)"
                    )
                }
            }
            
            // MARK: - Streak Progress
            VStack(alignment: .leading, spacing: 8) {
                Text("Exploration Streaks")
                    .font(.headline)
                
                HStack {
                    StatBox(
                        title: "Total Islands",
                        value: "\(streakStats.islandsUnlockedThisMonth)"
                    )
                    StatBox(
                        title: "Longest Streak",
                        value: "\(streakStats.longestStreak) days"
                    )
                    StatBox(
                        title: "Current Streak",
                        value: "\(streakStats.currentStreak) days"
                    )
                    StatBox(
                        title: "Total Steps",
                        value: "\(streakStats.totalStepsThisMonth)"
                    )
                }
            }
            
            // MARK: - Exploration Score
            VStack(alignment: .leading, spacing: 8) {
                Text("Exploration Score")
                    .font(.headline)
                
                HStack {
                    StatBox(title: "Total Score", value: "\(explorationScore.total)")
                    StatBox(title: "Steps", value: "\(explorationScore.breakdown.steps)")
                    StatBox(title: "Islands", value: "\(explorationScore.breakdown.islandsUnlocked)")
                    StatBox(title: "Streak Bonus", value: "\(explorationScore.breakdown.streakBonus)")
                }
            }
        }
    }
}

// MARK: - STAT BOX
struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - MAIN SUMMARY VIEW
struct SummaryView: View {
    
    // MARK: - MOCK DATA
    
    let dailyStats = DailyExplorationStats(
        stepsToday: 10432,
        leftHomeBubble: true,
        exploredToday: true,
        islandsUnlockedToday: 1
    )
    
    let streakStats = ExplorationStreakStats(
        islandsUnlockedThisMonth: 18,
        longestStreak: 14,
        currentStreak: 7,
        totalStepsThisMonth: 245_000,
    )
    
    let explorationScore = ExplorationScore(
        total: 542,
        breakdown: ExplorationScoreBreakdown(
            steps: 245,
            islandsUnlocked: 178,
            streakBonus: 119
        )
    )
    
    let achievements = MockData.achievements
    let weeklyData = MockData.weeklyData
    let monthlyScores = MockData.monthlyScores
    let calendarDays = MockData.calendarDays
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                
                // MARK: - Header
                HStack(spacing: 16) {
                    Image(systemName: "globe.americas.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading) {
                        Text("Exploration Summary")
                            .font(.title)
                            .bold()
                        
                        Text("Steps, streaks, and floating islands")
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // MARK: - Main Stats
                ExplorationProgressView(
                    dailyStats: dailyStats,
                    streakStats: streakStats,
                    explorationScore: explorationScore
                )
                
                // MARK: - Charts
                ExplorationChartsView(
                    weeklyData: weeklyData,
                    monthlyScores: monthlyScores
                )
                
                // MARK: - Streak Heatmap
                ExplorationStreakMapView(days: calendarDays)
                
                // MARK: - Achievements
                AchievementsGridView(achievements: achievements)
            }
            .padding()
        }
    }
}

// MARK: - DATA MODELS

struct DailyExplorationStats {
    let stepsToday: Int
    let leftHomeBubble: Bool
    let exploredToday: Bool
    let islandsUnlockedToday: Int
}

struct ExplorationStreakStats {
    let islandsUnlockedThisMonth: Int
    let longestStreak: Int
    let currentStreak: Int
    let totalStepsThisMonth: Int
}

struct ExplorationScore {
    let total: Int
    let breakdown: ExplorationScoreBreakdown
}

struct ExplorationScoreBreakdown {
    let steps: Int
    let islandsUnlocked: Int
    let streakBonus: Int
}

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let unlocked: Bool
    let progress: Int?
    let target: Int?
}

struct WeeklyExplorationData: Identifiable {
    let id = UUID()
    let day: String
    let steps: Int
    let explored: Bool
}

struct MonthlyExplorationScore: Identifiable {
    let id = UUID()
    let month: String
    let score: Int
}

struct ExplorationStreakDay: Identifiable {
    let id = UUID()
    let date: Date
    let explored: Bool
    let steps: Int
}

// MARK: - CHARTS
struct ExplorationChartsView: View {
    let weeklyData: [WeeklyExplorationData]
    let monthlyScores: [MonthlyExplorationScore]
    
    var body: some View {
        VStack(spacing: 24) {
            
            VStack(alignment: .leading) {
                Text("Weekly Steps & Exploration")
                    .font(.headline)
                
                Chart(weeklyData) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Steps", data.steps)
                    )
                }
                .frame(height: 200)
            }
            
            VStack(alignment: .leading) {
                Text("Monthly Exploration Score")
                    .font(.headline)
                
                Chart(monthlyScores) { data in
                    LineMark(
                        x: .value("Month", data.month),
                        y: .value("Score", data.score)
                    )
                }
                .frame(height: 200)
            }
        }
    }
}

// MARK: - STREAK MAP
struct ExplorationStreakMapView: View {
    let days: [ExplorationStreakDay]
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Exploration Streak Map")
                .font(.headline)
            
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(days) { day in
                    Rectangle()
                        .fill(day.explored ? Color.blue.opacity(min(Double(day.steps) / 20000.0, 1.0)) : Color.gray.opacity(0.2))
                        .frame(height: 20)
                        .cornerRadius(4)
                }
            }
        }
    }
}

// MARK: - ACHIEVEMENTS
struct AchievementsGridView: View {
    let achievements: [Achievement]
    
    let columns = [GridItem(.adaptive(minimum: 140))]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Achievements")
                .font(.headline)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(achievements) { achievement in
                    VStack(spacing: 8) {
                        Text(achievement.icon)
                            .font(.largeTitle)
                        
                        Text(achievement.title)
                            .bold()
                        
                        Text(achievement.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if !achievement.unlocked,
                           let progress = achievement.progress,
                           let target = achievement.target {
                            ProgressView(value: Double(progress), total: Double(target))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(achievement.unlocked ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    )
                }
            }
        }
    }
}

// MARK: - MOCK DATA
struct MockData {
    
    static let achievements: [Achievement] = [
        Achievement(id: "1", title: "Island Explorer", description: "Unlock 50 floating islands", icon: "🏝️", unlocked: true, progress: nil, target: nil),
        Achievement(id: "2", title: "Step Master", description: "Reach 1,000,000 steps", icon: "👟", unlocked: false, progress: 542_000, target: 1_000_000),
        Achievement(id: "3", title: "Streak Keeper", description: "Maintain a 30-day streak", icon: "🔥", unlocked: false, progress: 14, target: 30),
        Achievement(id: "4", title: "Streak Saver", description: "Save your streak after missing a day", icon: "❤️‍🔥", unlocked: false, progress: 3, target: 30)

    ]
    
    static let weeklyData: [WeeklyExplorationData] = [
        WeeklyExplorationData(day: "Mon", steps: 8200, explored: false),
        WeeklyExplorationData(day: "Tue", steps: 10200, explored: true),
        WeeklyExplorationData(day: "Wed", steps: 11500, explored: true),
        WeeklyExplorationData(day: "Thu", steps: 9800, explored: false),
        WeeklyExplorationData(day: "Fri", steps: 14300, explored: true),
        WeeklyExplorationData(day: "Sat", steps: 18000, explored: true),
        WeeklyExplorationData(day: "Sun", steps: 22000, explored: true)
    ]
    
    static let monthlyScores: [MonthlyExplorationScore] = [
        MonthlyExplorationScore(month: "Oct", score: 385),
        MonthlyExplorationScore(month: "Nov", score: 425),
        MonthlyExplorationScore(month: "Dec", score: 398),
        MonthlyExplorationScore(month: "Jan", score: 478),
        MonthlyExplorationScore(month: "Feb", score: 512),
        MonthlyExplorationScore(month: "Mar", score: 542)
    ]
    
    static let calendarDays: [ExplorationStreakDay] = {
        (0..<35).map { i in
            let date = Calendar.current.date(byAdding: .day, value: -34 + i, to: Date())!
            let steps = Int.random(in: 0...22000)
            return ExplorationStreakDay(
                date: date,
                explored: steps >= 10_000,
                steps: steps
            )
        }
    }()
}

#Preview {
    SummaryView()
}
