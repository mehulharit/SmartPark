import SwiftUI
import MapKit
import CoreLocation

struct DirectionsView: View {
    let spot: ParkingSpot

    @EnvironmentObject private var appLocationState: AppLocationState
    @Environment(\.openURL) private var openURL

    @State private var cameraPosition: MapCameraPosition
    @State private var route: MKRoute?
    @State private var isLoadingRoute = false
    @State private var showNoStartLocationAlert = false

    init(spot: ParkingSpot) {
        self.spot = spot
        _cameraPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: spot.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                )
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Map(position: $cameraPosition) {
                if let start = appLocationState.selectedCoordinate {
                    Annotation("Starting Point", coordinate: start) {
                        VStack(spacing: 4) {
                            Text(appLocationState.selectedLocationName.isEmpty ? "Start" : appLocationState.selectedLocationName)
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

                Annotation("Destination", coordinate: spot.coordinate) {
                    VStack(spacing: 4) {
                        Text(spot.name)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(radius: 1)

                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.red)
                    }
                }

                if let route {
                    MapPolyline(route.polyline)
                        .stroke(.blue, lineWidth: 4)
                }
            }
            .frame(height: 520)
            .task {
                await loadRoute()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Route to \(spot.name)")
                    .font(.title3)
                    .fontWeight(.semibold)

                if isLoadingRoute {
                    ProgressView()
                } else if let route {
                    Text("\(route.distance / 1609.34, specifier: "%.1f") miles • \(Int(route.expectedTravelTime / 60)) min")
                        .foregroundColor(.secondary)
                } else {
                    Text("\(spot.distanceText) • Estimated route")
                        .foregroundColor(.secondary)
                }

                Button {
                    startNavigation()
                } label: {
                    Text("Start Navigation")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 6)
            }
            .padding()
        }
        .navigationTitle("Directions")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let start = appLocationState.selectedCoordinate {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: start,
                        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                    )
                )
            }
        }
        .alert("No Starting Location", isPresented: $showNoStartLocationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please enter a location first so navigation can start from that point.")
        }
    }

    private func loadRoute() async {
        guard let startCoordinate = appLocationState.selectedCoordinate else {
            route = nil
            return
        }

        isLoadingRoute = true
        defer { isLoadingRoute = false }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: spot.coordinate))
        request.transportType = .automobile

        do {
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()
            route = response.routes.first

            if let route {
                let rect = route.polyline.boundingMapRect
                cameraPosition = .rect(rect)
            }
        } catch {
            print("Route error:", error.localizedDescription)
            route = nil
        }
    }

    private func startNavigation() {
        guard let start = appLocationState.selectedCoordinate else {
            showNoStartLocationAlert = true
            return
        }

        var components = URLComponents()
        components.scheme = "http"
        components.host = "maps.apple.com"
        components.queryItems = [
            URLQueryItem(name: "saddr", value: "\(start.latitude),\(start.longitude)"),
            URLQueryItem(name: "daddr", value: "\(spot.latitude),\(spot.longitude)"),
            URLQueryItem(name: "dirflg", value: "d")
        ]

        guard let url = components.url else { return }
        openURL(url)
    }
}
