import SwiftUI
import CoreLocation
import Combine

struct LocationSetupView: View {
    @EnvironmentObject private var appLocationState: AppLocationState
    @EnvironmentObject private var viewModel: ParkingViewModel

    @State private var locationText: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    @StateObject private var searchCompleter = SearchCompleterViewModel()

    private let apiService = ParkingAPIService()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.10),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Spacer(minLength: 16)

                        VStack(spacing: 10) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.blue)

                            Text("SmartPark")
                                .font(.largeTitle)
                                .fontWeight(.semibold)

                            Text("Enter your starting location to continue.")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        .padding(.top, 16)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Your Location")
                                .font(.headline)

                            TextField("City or address", text: $locationText)
                                .textFieldStyle(.roundedBorder)
                                .submitLabel(.go)
                                .onSubmit {
                                    Task {
                                        await continueWithTypedLocation()
                                    }
                                }
                                .onChange(of: locationText) { _, newValue in
                                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if trimmed.isEmpty {
                                        searchCompleter.results = []
                                    } else {
                                        searchCompleter.updateQuery(trimmed)
                                    }
                                }

                            if !searchCompleter.results.isEmpty &&
                                !locationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(searchCompleter.results.prefix(6), id: \.self) { item in
                                        Button {
                                            locationText = item
                                            searchCompleter.results = []
                                        } label: {
                                            HStack {
                                                Image(systemName: "location.magnifyingglass")
                                                    .foregroundColor(.blue)
                                                Text(item)
                                                    .foregroundColor(.primary)
                                                    .multilineTextAlignment(.leading)
                                                Spacer()
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 12)
                                        }
                                        .buttonStyle(.plain)

                                        if item != searchCompleter.results.prefix(6).last {
                                            Divider()
                                        }
                                    }
                                }
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Button {
                                Task {
                                    await continueWithTypedLocation()
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                    Text("Continue")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(locationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.blue.opacity(0.4) : Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(isLoading || locationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
                        .padding(.horizontal)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        Spacer(minLength: 12)
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private func continueWithTypedLocation() async {
        let trimmed = locationText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter a city or address."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let coordinate = try await apiService.geocodeLocation(query: trimmed)

            appLocationState.selectedCoordinate = coordinate
            appLocationState.selectedLocationName = trimmed
            appLocationState.usesManualLocation = true
            appLocationState.didCompleteLocationSetup = true

            viewModel.updateLocation(coordinate)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
