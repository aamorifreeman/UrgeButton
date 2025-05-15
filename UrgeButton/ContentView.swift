import SwiftUI
import UIKit   // for UIImpactFeedbackGenerator

// MARK: — Haptic Helper
func vibrate() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
}

struct ContentView: View {
    @StateObject private var store = UrgeStore()
    @State private var showingAdd = false
    
    // Which Urge is the “main” one?
    @State private var selectedID: UUID?
    @State private var isPressed = false
    @State private var showResetAlert = false

    // Convenience: the currently-selected Urge (or first if none tapped)
    private var mainUrge: Urge? {
        if let id = selectedID {
            return store.urges.first { $0.id == id }
        }
        return store.urges.first
    }

    var body: some View {
        ZStack {
            // 1. Background gradient
            LinearGradient(
                gradient: Gradient(colors: [.purple, .blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // 2. Horizontal chips to pick your urge
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

                // 3. Main urge display and buttons
                if let urge = mainUrge {
                    VStack(spacing: 16) {
                        Text(urge.name)
                            .font(.largeTitle).bold()
                            .foregroundColor(.white)

                        Text("\(urge.totalCount)")
                            .font(.system(size: 72, weight: .heavy))
                            .foregroundColor(.yellow)

                        // 4a. “I Resisted!” button with spring animation
                        Button {
                            vibrate()
                            withAnimation(.interpolatingSpring(stiffness: 300, damping: 15)) {
                                isPressed = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeOut) { isPressed = false }
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

                        // 4b. **New Reset button**
                        Button {
                            showResetAlert = true
                        } label: {
                            Text("Reset")
                                .font(.body).bold()
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

                // 5. “+” button to add new urges
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
        // 6. Sheet for adding a new urge
        .sheet(isPresented: $showingAdd) {
            AddUrgeView(store: store)
        }
        // 7. Alert to confirm reset
        .alert("Reset “\(mainUrge?.name ?? "")”?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                if let urge = mainUrge {
                    store.reset(urge: urge)
                }
            }
        } message: {
            Text("This will clear the count and current streak for this urge.")
        }
    }

    // MARK: – Nested AddUrgeView
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
                        Button("Cancel", role: .cancel) {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
