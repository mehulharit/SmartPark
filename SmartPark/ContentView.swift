import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appLocationState: AppLocationState
    @EnvironmentObject private var viewModel: ParkingViewModel

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationStack {
                ParkingListView()
            }
            .tabItem {
                Label("List", systemImage: "list.bullet")
            }

            NavigationStack {
                FavoritesView()
            }
            .tabItem {
                Label("Favorites", systemImage: "heart")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .tint(.blue)
        .onAppear {
            if let coordinate = appLocationState.selectedCoordinate {
                viewModel.updateLocation(coordinate)
            }
        }
    }
}
