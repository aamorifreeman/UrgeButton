import Foundation

struct Urge: Identifiable, Codable {
    let id: UUID
    var name: String
    
    // totals & streaks
    var totalCount: Int
    var currentStreak: Int
    var bestStreak: Int
    var lastTapDate: Date?
    
    // **NEW** daily logs keyed by "YYYY-MM-DD"
    var dailyResisted: [String:Int]
    var dailyRelapsed: [String:Int]
    
    var badgesEarned: [String]
    
    init(name: String) {
        self.id = .init()
        self.name = name
        self.totalCount    = 0
        self.currentStreak = 0
        self.bestStreak    = 0
        self.lastTapDate   = nil
        
        self.dailyResisted = [:]
        self.dailyRelapsed = [:]
        
        self.badgesEarned = []
    }
}
