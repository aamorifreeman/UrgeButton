import SwiftUI
import UIKit   // for haptics

// MARK: – Haptic Helper
func vibrate() {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
}

struct ContentView: View {
    // 1️⃣ Accept the shared store instead of creating your own
    @ObservedObject var store: UrgeStore

    @State private var showingAdd     = false
    @State private var selectedID     : UUID?
    @State private var isPressed      = false
    @State private var showResetAlert = false

    private var mainUrge: Urge? {
        if let id = selectedID {
            return store.urges.first { $0.id == id }
        }
        return store.urges.first
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.purple, .blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // 2️⃣ Your “chips selector” stays the same…
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(store.urges) { urge in
                            Text(urge.name)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            urge.id == mainUrge?.id
                                              ? Color.white.opacity(0.8)
                                              : Color.white.opacity(0.3)
                                        )
                                )
                                .foregroundColor(.black)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        selectedID = urge.id
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // 3️⃣ Main urge & daily stats UI (unchanged)
                if let urge = mainUrge {
                    let todayKey      = UrgeStore.dayFormatter.string(from: Date())
                    let todayResisted = urge.dailyResisted[todayKey] ?? 0
                    let todayRelapsed = urge.dailyRelapsed[todayKey] ?? 0

                    VStack(spacing: 16) {
                        Text(urge.name)
                          .font(.largeTitle).bold()
                          .foregroundColor(.white)

                        Text("\(urge.totalCount)")
                          .font(.system(size: 72, weight: .heavy))
                          .foregroundColor(.yellow)

                        HStack(spacing: 24) {
                            VStack {
                                Text("\(todayResisted)")
                                  .font(.title2).bold()
                                Text("rescued today")
                                  .font(.caption)
                                  .foregroundColor(.white.opacity(0.8))
                            }
                            VStack {
                                Text("\(todayRelapsed)")
                                  .font(.title2).bold()
                                Text("relapsed today")
                                  .font(.caption)
                                  .foregroundColor(.white.opacity(0.8))
                            }
                        }

                        Button {
                            vibrate()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                isPressed = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
                                withAnimation { isPressed = false }
                            }
                            store.recordTap(on: urge)
                        } label: {
                            Text("I Resisted!")
                              .font(.title2).bold()
                              .padding(.vertical, 20)
                              .padding(.horizontal, 40)
                              .background(
                                  Capsule()
                                    .fill(Color.green)
                                    .shadow(color: .green.opacity(0.6), radius: 10, x: 0, y: 5)
                              )
                              .foregroundColor(.white)
                              .scaleEffect(isPressed ? 1.2 : 1.0)
                        }

                        Button {
                            showResetAlert = true
                        } label: {
                            Text("Reset")
                              .bold()
                              .padding(.vertical, 12)
                              .padding(.horizontal, 24)
                              .background(
                                  Capsule()
                                    .stroke(Color.red, lineWidth: 2)
                              )
                              .foregroundColor(.white)
                        }
                        .padding(.top, 8)
                    }

                } else {
                    Text("No urges yet—tap + to add one!")
                      .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                // 4️⃣ “+” button (same as before)
                HStack {
                    Spacer()
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                          .font(.system(size: 48))
                          .foregroundColor(.white)
                          .shadow(radius: 5)
                    }
                    .padding()
                }
            }
        }
        // 5️⃣ Sheet & alert (same as before)
        .sheet(isPresented: $showingAdd) {
            AddUrgeView(store: store)
        }
        .alert("Reset “\(mainUrge?.name ?? "")”?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                if let urge = mainUrge {
                    store.reset(urge: urge)
                }
            }
        } message: {
            Text("This will log a relapse for today and clear your streak.")
        }
    }

    // MARK: – Nested AddUrgeView (no changes here)
    struct AddUrgeView: View {
        @Environment(\.dismiss) private var dismiss
        @ObservedObject var store: UrgeStore
        @State private var name = ""

        var body: some View {
            NavigationView {
                Form {
                    TextField("What urge?", text: $name)
                }
                .navigationTitle("New Urge")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            let trimmed = name.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty {
                                store.add(trimmed)
                            }
                            dismiss()
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel) { dismiss() }
                    }
                }
            }
        }
    }
}
