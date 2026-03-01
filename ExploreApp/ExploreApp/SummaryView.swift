//
//  SummaryView.swift
//  ExploreApp
//
//  Created by Jono Tan on 3/1/26.
//

import SwiftUI
import Charts

//EXPLORATION STATS VIEW
struct ExplorationStatsView: View {
    let dailyStats: DailyStats
    let monthlyStats: MonthlyStats
    let adventureScore: AdventureScore
    
    var body: some View {
        VStack(spacing: 24) {
            // Daily Stats
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Stats")
                    .font(.headline)
                HStack {
                    StatBox(title: "New Places", value: "\(dailyStats.newPlaces)")
                    StatBox(title: "Farthest Distance", value: String(format: "%.1f km", dailyStats.farthestDistance))
                    StatBox(title: "Time Outdoors", value: String(format: "%.1f hrs", dailyStats.timeOutdoors))
                }
            }
            
            // Monthly Stats
            VStack(alignment: .leading, spacing: 8) {
                Text("Monthly Stats")
                    .font(.headline)
                HStack {
                    StatBox(title: "Total New Places", value: "\(monthlyStats.totalNewPlaces)")
                    StatBox(title: "Longest Streak", value: "\(monthlyStats.longestStreak) days")
                    StatBox(title: "Current Streak", value: "\(monthlyStats.currentStreak) days")
                    StatBox(title: "Total Distance", value: "\(monthlyStats.totalDistance) km")
                }
            }
            
            // Adventure Score
            VStack(alignment: .leading, spacing: 8) {
                Text("Adventure Score")
                    .font(.headline)
                HStack {
                    StatBox(title: "Total Score", value: "\(adventureScore.total)")
                    StatBox(title: "Distance", value: "\(adventureScore.breakdown.distance)")
                    StatBox(title: "New Tiles", value: "\(adventureScore.breakdown.newTiles)")
                    StatBox(title: "Time Outdoors", value: "\(adventureScore.breakdown.timeOutdoors)")
                }
            }
        }
    }
}

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

//MAIN APP VIEW
struct SummaryView: View {
    
    // MARK: - Mock Data
    
    let dailyStats = DailyStats(
        newPlaces: 7,
        farthestDistance: 12.5,
        timeOutdoors: 3.5
    )
    
    let monthlyStats = MonthlyStats(
        totalNewPlaces: 89,
        longestStreak: 14,
        currentStreak: 7,
        totalDistance: 245
    )
    
    let adventureScore = AdventureScore(
        total: 542,
        breakdown: AdventureBreakdown(
            distance: 245,
            newTiles: 178,
            timeOutdoors: 119
        )
    )
    
    let achievements = MockData.achievements
    let weeklyData = MockData.weeklyData
    let monthlyComparison = MockData.monthlyComparison
    let calendarDays = MockData.calendarDays
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                
                // MARK: - Header
                HStack(spacing: 16) {
                    Image(systemName: "location.north.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading) {
                        Text("Exploration Summary")
                            .font(.title)
                            .bold()
                        
                        Text("Track your adventures and discoveries")
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // MARK: - Main Stats
                ExplorationStatsView(
                    dailyStats: dailyStats,
                    monthlyStats: monthlyStats,
                    adventureScore: adventureScore
                )
                
                // MARK: - Charts
                ExplorationChartsView(
                    weeklyData: weeklyData,
                    monthlyComparison: monthlyComparison
                )
                
                // MARK: - Heat Map
                StreakCalendarView(days: calendarDays)
                
                // MARK: - Achievements
                AchievementsGridView(achievements: achievements)
            }
            .padding()
        }
    }
}

// DATA MODELS
struct DailyStats {
    let newPlaces: Int
    let farthestDistance: Double
    let timeOutdoors: Double
}

struct MonthlyStats {
    let totalNewPlaces: Int
    let longestStreak: Int
    let currentStreak: Int
    let totalDistance: Double
}

struct AdventureScore {
    let total: Int
    let breakdown: AdventureBreakdown
}

struct AdventureBreakdown {
    let distance: Int
    let newTiles: Int
    let timeOutdoors: Int
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

struct WeeklyData: Identifiable {
    let id = UUID()
    let day: String
    let places: Int
    let distance: Double
}

struct MonthlyComparison: Identifiable {
    let id = UUID()
    let month: String
    let score: Int
}

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let explored: Bool
    let count: Int
}


//CHARTS COMPONENT
struct ExplorationChartsView: View {
    let weeklyData: [WeeklyData]
    let monthlyComparison: [MonthlyComparison]
    
    var body: some View {
        VStack(spacing: 24) {
            
            // Weekly Chart
            VStack(alignment: .leading) {
                Text("Weekly Activity")
                    .font(.headline)
                
                Chart(weeklyData) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Places", data.places)
                    )
                }
                .frame(height: 200)
            }
            
            // Monthly Comparison
            VStack(alignment: .leading) {
                Text("Monthly Score")
                    .font(.headline)
                
                Chart(monthlyComparison) { data in
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

// ACHIEVEMENTS GRID
struct AchievementsGridView: View {
    let achievements: [Achievement]
    
    let columns = [
        GridItem(.adaptive(minimum: 140))
    ]
    
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
                            ProgressView(value: Double(progress),
                                         total: Double(target))
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

//Streak Calendar
struct StreakCalendarView: View {
    let days: [CalendarDay]
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Activity Heatmap")
                .font(.headline)
            
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(days) { day in
                    Rectangle()
                        .fill(day.explored ? Color.blue.opacity(Double(day.count) / 12.0) : Color.gray.opacity(0.2))
                        .frame(height: 20)
                        .cornerRadius(4)
                }
            }
        }
    }
}

//Mock Data Helper
struct MockData {
    
    static let achievements: [Achievement] = [
        Achievement(id: "1", title: "Explorer", description: "Visit 50 new places", icon: "🗺️", unlocked: true, progress: nil, target: nil),
        Achievement(id: "2", title: "Marathon", description: "Travel 100km in a month", icon: "🏃", unlocked: true, progress: nil, target: nil),
        Achievement(id: "3", title: "Early Bird", description: "Explore before 7 AM", icon: "🌅", unlocked: true, progress: nil, target: nil),
        Achievement(id: "4", title: "Night Owl", description: "Explore after 9 PM", icon: "🦉", unlocked: false, progress: 3, target: 5),
        Achievement(id: "5", title: "Streak Master", description: "30 day streak", icon: "🔥", unlocked: false, progress: 14, target: 30),
        Achievement(id: "6", title: "Century", description: "Visit 100 places", icon: "💯", unlocked: false, progress: 89, target: 100),
        Achievement(id: "7", title: "Adventurer", description: "Reach 1000 score", icon: "⭐", unlocked: false, progress: 542, target: 1000),
        Achievement(id: "8", title: "Weekend Warrior", description: "Explore every weekend", icon: "🎯", unlocked: false, progress: 2, target: 4),
    ]
    
    static let weeklyData: [WeeklyData] = [
        WeeklyData(day: "Mon", places: 8, distance: 15),
        WeeklyData(day: "Tue", places: 5, distance: 12),
        WeeklyData(day: "Wed", places: 12, distance: 22),
        WeeklyData(day: "Thu", places: 9, distance: 18),
        WeeklyData(day: "Fri", places: 15, distance: 28),
        WeeklyData(day: "Sat", places: 18, distance: 35),
        WeeklyData(day: "Sun", places: 22, distance: 42)
    ]
    
    static let monthlyComparison: [MonthlyComparison] = [
        MonthlyComparison(month: "Oct", score: 385),
        MonthlyComparison(month: "Nov", score: 425),
        MonthlyComparison(month: "Dec", score: 398),
        MonthlyComparison(month: "Jan", score: 478),
        MonthlyComparison(month: "Feb", score: 512),
        MonthlyComparison(month: "Mar", score: 542),
    ]
    
    static let calendarDays: [CalendarDay] = {
        (0..<35).map { i in
            let date = Calendar.current.date(byAdding: .day, value: -34 + i, to: Date())!
            let count = Int.random(in: 0...12)
            return CalendarDay(
                date: date,
                explored: count > 0,
                count: count
            )
        }
    }()
}

#Preview {
    SummaryView()
}
