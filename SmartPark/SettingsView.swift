import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var viewModel: ParkingViewModel
    @Query private var preferences: [ParkingPreferences]

    @State private var maxPrice: Double = 10
    @State private var maxDistance: Double = 3
    @State private var onlyAvailable: Bool = false
    @State private var availabilityAlertsEnabled: Bool = true
    @State private var priceAlertsEnabled: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Maximum Price")
                            .font(.headline)
                        Spacer()
                        Text("$\(Int(maxPrice))/hr")
                            .foregroundColor(.blue)
                    }
                    Slider(value: $maxPrice, in: 1...10, step: 1)
                    HStack {
                        Text("$1")
                        Spacer()
                        Text("$10")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Preferred Walking Distance")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.1f mi", maxDistance))
                            .foregroundColor(.blue)
                    }
                    Slider(value: $maxDistance, in: 0.5...3, step: 0.1)
                    HStack {
                        Text("0.5 mi")
                        Spacer()
                        Text("3 mi")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Preferences")
                        .font(.headline)

                    Toggle("Only show available parking", isOn: $onlyAvailable)
                    Toggle("Parking availability alerts", isOn: $availabilityAlertsEnabled)
                    Toggle("Price change notifications", isOn: $priceAlertsEnabled)
                }

                Button {
                    savePreferences()
                } label: {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("User Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadPreferences()
        }
    }

    private func loadPreferences() {
        let current = preferences.first ?? ParkingPreferences()
        if preferences.isEmpty {
            modelContext.insert(current)
        }

        maxPrice = current.maxPrice
        maxDistance = current.maxDistance
        onlyAvailable = current.onlyAvailable
        availabilityAlertsEnabled = current.availabilityAlertsEnabled
        priceAlertsEnabled = current.priceAlertsEnabled

        viewModel.maxPrice = current.maxPrice
        viewModel.maxDistance = current.maxDistance
        viewModel.onlyAvailable = current.onlyAvailable
    }

    private func savePreferences() {
        let current = preferences.first ?? ParkingPreferences()
        current.maxPrice = maxPrice
        current.maxDistance = maxDistance
        current.onlyAvailable = onlyAvailable
        current.availabilityAlertsEnabled = availabilityAlertsEnabled
        current.priceAlertsEnabled = priceAlertsEnabled

        if preferences.isEmpty {
            modelContext.insert(current)
        }

        viewModel.maxPrice = maxPrice
        viewModel.maxDistance = maxDistance
        viewModel.onlyAvailable = onlyAvailable

        try? modelContext.save()
    }
}
