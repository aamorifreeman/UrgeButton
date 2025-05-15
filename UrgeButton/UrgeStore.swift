import Foundation

class UrgeStore: ObservableObject {
    @Published var urges: [Urge] = [] {
        didSet { save() }
    }
    private let key = "savedUrges"
    
    init() { load() }
    
    func add(_ name: String) {
        urges.append(.init(name: name))
    }
    
    func recordTap(on urge: Urge) {
        guard let idx = urges.firstIndex(where: { $0.id == urge.id }) else { return }
        var u = urges[idx]
        let today = Calendar.current.startOfDay(for: .now)
        
        // Total count
        u.totalCount += 1
        
        // Streak logic
        if let last = u.lastTapDate {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            if Calendar.current.isDate(last, inSameDayAs: yesterday) {
                u.currentStreak += 1
            } else if !Calendar.current.isDate(last, inSameDayAs: today) {
                u.currentStreak = 1
            }
        } else {
            u.currentStreak = 1
        }
        
        u.lastTapDate = today
        u.bestStreak = max(u.bestStreak, u.currentStreak)
        
        // Badge rewards
        for m in [7, 30, 100] {
            let badge = "\(m)-Day Streak"
            if u.currentStreak == m && !u.badgesEarned.contains(badge) {
                u.badgesEarned.append(badge)
            }
        }
        
        urges[idx] = u
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Urge].self, from: data)
        else { return }
        urges = decoded
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(urges) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

extension UrgeStore {
    /// Clears count & streak for a given urge
    func reset(urge: Urge) {
        guard let idx = urges.firstIndex(where: { $0.id == urge.id }) else { return }
        var u = urges[idx]
        u.totalCount    = 0
        u.currentStreak = 0
        u.lastTapDate   = nil
        urges[idx]      = u
    }
}
