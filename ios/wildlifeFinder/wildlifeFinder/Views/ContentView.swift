//
import SwiftUI

struct ContentView: View {
    @Environment(SightingMapViewModel.self) private var vm
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
                    Tab(value: 0) {
                        // SightingMapView()
                        NavigationStack {
                            SightingMapView()
                        }
                        
                    }
                    
                    Tab(value: 1) {
                        // route view or wtv
                        NavigationStack {
                            RouteStackView()
                        }
                    }
                    
                    Tab(value: 2) {
                        // go to choose add pic / sound
                        NavigationStack {
                            PostFlowView()
                        }
                    }
                    
                    Tab(value: 3) {
                        // animal search
                        NavigationStack {
                            AnimalSearchView()
                        }
                    }
                    
                    Tab(value: 4) {
                        // user dashboard
                        NavigationStack {
                            UserDashboardView()
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .safeAreaInset(edge: .bottom){
                    BottomTabBarView(selectedTab: $selectedTab)
                }.ignoresSafeArea()
    }
}

#Preview {
    ContentView()
        .environment(SightingMapViewModel())
        .environment(RouteViewModel())
        .environment(DashboardViewModel())
}
