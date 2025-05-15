import SwiftUI
import Charts   // ← iOS 16+ Charts framework

// A simple struct to drive our chart
struct DayData: Identifiable {
    let id = UUID()
    let date: Date
    let resisted: Int
    let relapsed: Int
}

struct StatsView: View {
    @ObservedObject var store: UrgeStore
    @State private var selectedID: UUID?

    // Pick which Urge to chart (default first)
    private var mainUrge: Urge? {
        if let id = selectedID {
            return store.urges.first { $0.id == id }
        }
        return store.urges.first
    }

    // Transform your dictionaries into sorted DayData
    private var dayData: [DayData] {
        guard let urge = mainUrge else { return [] }
        return urge.dailyResisted.keys
            .compactMap { dayString in
                guard let date = UrgeStore.dayFormatter.date(from: dayString) else { return nil }
                let r = urge.dailyResisted[dayString] ?? 0
                let l = urge.dailyRelapsed[dayString] ?? 0
                return DayData(date: date, resisted: r, relapsed: l)
            }
            .sorted { $0.date < $1.date }
    }

    // Summary metrics
    private var totalDays: Int { dayData.count }
    private var totalResisted: Int { dayData.map(\.resisted).reduce(0, +) }
    private var totalRelapsed: Int { dayData.map(\.relapsed).reduce(0, +) }
    private var longestNoRelapseStreak: Int {
        var maxStreak = 0, current = 0
        for point in dayData {
            if point.relapsed == 0 {
                current += 1
                maxStreak = max(maxStreak, current)
            } else {
                current = 0
            }
        }
        return maxStreak
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // 1) Urge picker if you have >1
                if store.urges.count > 1 {
                    Picker("Urge", selection: $selectedID) {
                        ForEach(store.urges) { u in
                            Text(u.name).tag(u.id as UUID?)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }

                // 2) Summary cards
                HStack(spacing: 12) {
                    StatCard(value: totalDays, label: "Days")
                    StatCard(value: totalResisted, label: "Resisted")
                    StatCard(value: totalRelapsed, label: "Relapsed")
                    StatCard(value: longestNoRelapseStreak, label: "Max Streak")
                }
                .padding(.horizontal)

                // 3) Line chart
                Chart {
                    ForEach(dayData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Resisted", point.resisted)
                        )
                        .foregroundStyle(.green)

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Relapsed", point.relapsed)
                        )
                        .foregroundStyle(.red)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: dayData.count))
                }
                .frame(height: 200)
                .padding()

                Spacer()
            }
            .navigationTitle("Stats & Insights")
            .onAppear {
                // default selection
                if selectedID == nil {
                    selectedID = store.urges.first?.id
                }
            }
        }
    }
}

// A little reusable card for the top row
private struct StatCard: View {
    let value: Int
    let label: String

    var body: some View {
        VStack {
            Text("\(value)").font(.title).bold()
            Text(label).font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
    }
}
