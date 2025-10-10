import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var mapViewModel = MapViewModel()
    @StateObject private var sightingViewModel = SightingCreateViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Map Tab
            MapView()
                .environmentObject(mapViewModel)
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
                .tag(0)
            
            // Capture Tab
            CaptureView()
                .environmentObject(sightingViewModel)
                .tabItem {
                    Image(systemName: "camera")
                    Text("Capture")
                }
                .tag(1)
            
            // Route Tab
            RouteView()
                .environmentObject(mapViewModel)
                .tabItem {
                    Image(systemName: "location")
                    Text("Route")
                }
                .tag(2)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
}

