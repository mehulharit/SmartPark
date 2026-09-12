import SwiftUI
import MapKit
import CoreLocation
import Combine

struct HomeView: View {
    @EnvironmentObject private var viewModel: ParkingViewModel
    @EnvironmentObject private var appLocationState: AppLocationState

    @StateObject private var searchCompleter = SearchCompleterViewModel()
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
        )
    )

    @State private var navigateToParkingList = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let apiService = ParkingAPIService()

    var body: some View {
        VStack(spacing: 0) {
            Text("SmartPark")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 12)

            if !appLocationState.selectedLocationName.isEmpty {
                Text("Starting from: \(appLocationState.selectedLocationName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }

            SearchBarView(text: $viewModel.searchText) {
                // Search is applied when the user taps View Parking List.
            }
            .onChange(of: viewModel.searchText) { _, newValue in
                searchCompleter.updateQuery(newValue)
            }

            if !searchCompleter.results.isEmpty &&
                !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                List(searchCompleter.results, id: \.self) { item in
                    Button {
                        viewModel.searchText = item
                        searchCompleter.results = []
                    } label: {
                        Text(item)
                            .foregroundColor(.primary)
                    }
                }
                .frame(height: min(CGFloat(searchCompleter.results.count) * 44, 220))
            }

            ZStack(alignment: .bottomTrailing) {
                Map(position: $cameraPosition) {
                    if let coordinate = appLocationState.selectedCoordinate {
                        Annotation("Starting Location", coordinate: coordinate) {
                            VStack(spacing: 4) {
                                Text(appLocationState.selectedLocationName.isEmpty ? "Selected Location" : appLocationState.selectedLocationName)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .shadow(radius: 1)

                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                }
                .frame(height: 560)

                Button {
                    recenterToSelectedLocation()
                } label: {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 52, height: 52)
                        .shadow(radius: 3)
                        .overlay(
                            Image(systemName: "location.north.line.fill")
                                .foregroundColor(.blue)
                                .rotationEffect(.degrees(45))
                        )
                }
                .padding(.trailing, 16)
                .padding(.bottom, 18)
            }

            Button {
                Task {
                    await loadParkingAndNavigate()
                }
            } label: {
                Text("View Parking List")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }

            Spacer(minLength: 0)
        }
        .navigationBarHidden(true)
        .onAppear {
            if let coordinate = appLocationState.selectedCoordinate {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
                    )
                )
            }
        }
        .onReceive(appLocationState.$selectedCoordinate.compactMap { $0 }) { coordinate in
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
                )
            )
        }
        .navigationDestination(isPresented: $navigateToParkingList) {
            ParkingListView()
        }
        .alert("SmartPark", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func recenterToSelectedLocation() {
        guard let coordinate = appLocationState.selectedCoordinate else {
            errorMessage = "No location has been set yet."
            showError = true
            return
        }

        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
                )
            )
        }
    }

    private func loadParkingAndNavigate() async {
        let trimmedSearch = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedSearch.isEmpty {
            do {
                let coordinate = try await apiService.geocodeLocation(query: trimmedSearch)
                appLocationState.selectedCoordinate = coordinate
                appLocationState.selectedLocationName = trimmedSearch
                appLocationState.usesManualLocation = true
                viewModel.updateLocation(coordinate)
                await viewModel.loadParkingNear(coordinate: coordinate)
                navigateToParkingList = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            return
        }

        guard let coordinate = appLocationState.selectedCoordinate else {
            errorMessage = "Please enter a location on the first screen."
            showError = true
            return
        }

        await viewModel.loadParkingNear(coordinate: coordinate)
        navigateToParkingList = true
    }
}
