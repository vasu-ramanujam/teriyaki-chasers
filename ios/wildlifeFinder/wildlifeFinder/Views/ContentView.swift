import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack { SightingMapView() }
                .tabItem {
                    Image(systemName: "map")
                    Text("Sighting Map")
                }

            NavigationStack { RouteStackView(waypoints: []) }
                .tabItem {
                    Image(systemName: "point.bottomleft.forward.to.arrow.triangle.scurvepath.fill")
                    Text("Current Route")
                }

            NavigationStack { Text("Post Sighting (stub)") }
                .tabItem {
                    Image(systemName: "plus")
                    Text("Add")
                }

            NavigationStack { Text("Animal Search (stub)") }
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Animal Search")
                }

            NavigationStack { Text("User Dashboard (stub)") }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("User Dashboard")
                }
        }
    }
}

#Preview {
    ContentView()
}