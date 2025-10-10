import Foundation
import MapKit
import CoreLocation

@MainActor
class MapViewModel: NSObject, ObservableObject {
    @Published var sightings: [Sighting] = []
    @Published var selectedSighting: Sighting?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var selectedSpecies: Species?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private let apiClient = APIClient.shared
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestLocationPermission()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func loadSightings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let bbox = createBoundingBoxString()
            let newSightings = try await apiClient.getSightings(
                bbox: bbox,
                speciesId: selectedSpecies?.id
            )
            
            sightings = newSightings
        } catch {
            errorMessage = "Failed to load sightings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func filterBySpecies(_ species: Species?) {
        selectedSpecies = species
        Task {
            await loadSightings()
        }
    }
    
    func selectSighting(_ sighting: Sighting) {
        selectedSighting = sighting
        region.center = sighting.coordinate
    }
    
    private func createBoundingBoxString() -> String {
        let center = region.center
        let span = region.span
        
        let north = center.latitude + span.latitudeDelta / 2
        let south = center.latitude - span.latitudeDelta / 2
        let east = center.longitude + span.longitudeDelta / 2
        let west = center.longitude - span.longitudeDelta / 2
        
        return "\(west),\(south),\(east),\(north)"
    }
}

extension MapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        region.center = location.coordinate
        Task {
            await loadSightings()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location error: \(error.localizedDescription)"
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
}

