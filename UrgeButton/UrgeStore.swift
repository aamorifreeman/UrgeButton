import Foundation

class UrgeStore: ObservableObject {
    @Published var urges: [Urge] = [] { didSet { save() } }
    private let key = "savedUrges"
    
    // Formatter to normalize dates to "YYYY-MM-DD"
    static let dayFormatter: DateFormatter = {
      let f = DateFormatter()
      f.dateFormat = "yyyy-MM-dd"
      f.calendar   = Calendar(identifier: .gregorian)
      f.timeZone   = .current
      return f
    }()
    
    init() { load() }
    
    func add(_ name: String) {
        urges.append(.init(name: name))
    }
    
    func recordTap(on urge: Urge) {
        guard let idx = urges.firstIndex(where: { $0.id == urge.id }) else { return }
        var u = urges[idx]
        let today   = Date()
        let dayKey  = Self.dayFormatter.string(from: today)
        let dayStart = Calendar.current.startOfDay(for: today)
        
        // 1) Update total
        u.totalCount += 1
        
        // 2) Update daily resisted
        u.dailyResisted[dayKey, default: 0] += 1
        
        // 3) Streak logic (unchanged)
        if let last = u.lastTapDate {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: dayStart)!
            if Calendar.current.isDate(last, inSameDayAs: yesterday) {
                u.currentStreak += 1
            } else if !Calendar.current.isDate(last, inSameDayAs: dayStart) {
                u.currentStreak = 1
            }
        } else {
            u.currentStreak = 1
        }
        
        u.lastTapDate = dayStart
        u.bestStreak  = max(u.bestStreak, u.currentStreak)
        
        // 4) Badge rewards (unchanged)
        for m in [7,30,100] {
          let badge = "\(m)-Day Streak"
          if u.currentStreak == m && !u.badgesEarned.contains(badge) {
            u.badgesEarned.append(badge)
          }
        }
        
        urges[idx] = u
    }
    
    func reset(urge: Urge) {
        guard let idx = urges.firstIndex(where: { $0.id == urge.id }) else { return }
        var u = urges[idx]
        let dayKey = Self.dayFormatter.string(from: Date())
        
        // Log a relapse today
        u.dailyRelapsed[dayKey, default: 0] += 1
        
        // Clear counts & streak
        u.totalCount    = 0
        u.currentStreak = 0
        u.lastTapDate   = nil
        
        urges[idx] = u
    }
    
    // MARK: — Persistence
    
    private func load() {
        guard
          let data = UserDefaults.standard.data(forKey: key),
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
