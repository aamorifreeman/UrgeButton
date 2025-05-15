import SwiftUI
import UIKit   // for UIImpactFeedbackGenerator

// MARK: – Haptic Helper
func vibrate() {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
}

struct ContentView: View {
    @ObservedObject var store: UrgeStore

    @State private var showingAdd      = false
    @State private var showResetAlert  = false
    @State private var showRenameSheet = false

    @State private var selectedID     : UUID?
    @State private var editingUrge    : Urge?
    @State private var newUrgeName    = ""
    @State private var isPressed      = false

    // Which urge is in the “main” spotlight?
    private var mainUrge: Urge? {
        if let id = selectedID {
            return store.urges.first { $0.id == id }
        }
        return store.urges.first
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [.purple, .blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // ─── 1) CHIPS SELECTOR ───
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(store.urges) { urge in
                            urgeChip(for: urge)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // ─── 2) MAIN URGE & STATS ───
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

                        // Daily stats
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

                        // “I Resisted!” button
                        Button {
                            vibrate()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                isPressed = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
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
                                        .shadow(color: .green.opacity(0.6),
                                                radius: 10, x: 0, y: 5)
                                )
                                .foregroundColor(.white)
                                .scaleEffect(isPressed ? 1.2 : 1.0)
                        }

                        // Reset (relapse) button
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

                // ─── 3) “+” ADD BUTTON ───
                HStack {
                    Spacer()
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                    }
                    .padding()
                }
            }
        }
        // ─── 4) SHEETS & ALERTS ───
        .sheet(isPresented: $showingAdd) {
            AddUrgeView(store: store)
        }
        .alert("Reset “\(mainUrge?.name ?? "")”?",
               isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                if let u = mainUrge { store.reset(urge: u) }
            }
        } message: {
            Text("This will log a relapse for today and clear your streak.")
        }
        .sheet(isPresented: $showRenameSheet) {
            NavigationView {
                Form {
                    TextField("New name", text: $newUrgeName)
                }
                .navigationTitle("Rename Urge")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if let u = editingUrge,
                               let idx = store.urges.firstIndex(where: { $0.id == u.id }) {
                                store.urges[idx].name =
                                    newUrgeName.trimmingCharacters(in: .whitespaces)
                            }
                            showRenameSheet = false
                        }
                        .disabled(newUrgeName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel) {
                            showRenameSheet = false
                        }
                    }
                }
            }
        }
    } // end of body

    // MARK: – Chip helper pulled out for compiler performance
    @ViewBuilder
    private func urgeChip(for urge: Urge) -> some View {
        // Extract the background color to a separate variable
        let backgroundColor = urge.id == mainUrge?.id
            ? Color.white.opacity(0.8)
            : Color.white.opacity(0.3)
        
        Text(urge.name)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
            .foregroundColor(.black)
            .onTapGesture {
                withAnimation(.spring()) {
                    selectedID = urge.id
                }
            }
            .contextMenu {
                Button("Rename", systemImage: "pencil") {
                    editingUrge = urge
                    newUrgeName = urge.name
                    showRenameSheet = true
                }
                Button("Delete", systemImage: "trash", role: .destructive) {
                    if let idx = store.urges.firstIndex(where: { $0.id == urge.id }) {
                        store.urges.remove(at: idx)
                        if urge.id == selectedID {
                            selectedID = store.urges.first?.id
                        }
                    }
                }
            }
    }

    // MARK: – Nested AddUrgeView (unchanged)
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
