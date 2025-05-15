import Foundation

struct Urge: Identifiable, Codable {
    let id: UUID
    var name: String
    var totalCount: Int
    var currentStreak: Int
    var bestStreak: Int
    var lastTapDate: Date?
    var badgesEarned: [String]
    
    init(name: String) {
        self.id = .init()
        self.name = name
        self.totalCount = 0
        self.currentStreak = 0
        self.bestStreak = 0
        self.lastTapDate = nil
        self.badgesEarned = []
    }
}
