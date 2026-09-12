import SwiftUI
import MapKit
import CoreLocation
import Combine

struct ParkingListView: View {
    @EnvironmentObject private var viewModel: ParkingViewModel
    @EnvironmentObject private var appLocationState: AppLocationState

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        )
    )

    @State private var didLoadParking = false
    @State private var selectedSpot: ParkingSpot?

    var body: some View {
        VStack(spacing: 0) {
            Map(position: $cameraPosition) {
                if let coordinate = appLocationState.selectedCoordinate {
                    Annotation("Selected Location", coordinate: coordinate) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                    }
                }

                ForEach(viewModel.filteredSpots) { spot in
                    Annotation(spot.name, coordinate: spot.coordinate) {
                        Button {
                            selectedSpot = spot
                        } label: {
                            VStack(spacing: 4) {
                                Text(spot.priceText)
                                    .font(.caption2)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 4)
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .shadow(radius: 1)

                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.red)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(height: 320)
            .onAppear {
                updateCameraToSelectedLocation()
                loadParkingIfNeeded()
            }
            .onReceive(appLocationState.$selectedCoordinate.compactMap { $0 }) { _ in
                updateCameraToSelectedLocation()
                loadParkingIfNeeded(forceReload: true)
            }

            List {
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if viewModel.filteredSpots.isEmpty {
                    ContentUnavailableView(
                        "No Parking Loaded",
                        systemImage: "car",
                        description: Text("Go back to Home and tap View Parking List.")
                    )
                } else {
                    ForEach(viewModel.filteredSpots) { spot in
                        NavigationLink {
                            ParkingDetailView(spot: spot)
                        } label: {
                            ParkingRowView(spot: spot)
                        }
                    }
                }
            }
        }
        .navigationTitle("Parking Locations")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 8)
            }
        }
        .onReceive(viewModel.$region) { newRegion in
            cameraPosition = .region(newRegion)
        }
        .navigationDestination(item: $selectedSpot) { spot in
            ParkingDetailView(spot: spot)
        }
    }

    private func updateCameraToSelectedLocation() {
        if let coordinate = appLocationState.selectedCoordinate {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                )
            )
        }
    }

    private func loadParkingIfNeeded(forceReload: Bool = false) {
        guard forceReload || !didLoadParking || viewModel.filteredSpots.isEmpty else { return }
        didLoadParking = true

        if let coordinate = appLocationState.selectedCoordinate {
            Task {
                await viewModel.loadParkingNear(coordinate: coordinate)
            }
        }
    }
}
