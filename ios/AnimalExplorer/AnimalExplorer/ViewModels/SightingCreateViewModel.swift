import Foundation
import UIKit
import CoreLocation

@MainActor
class SightingCreateViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var identificationCandidates: [IdentificationCandidate] = []
    @Published var selectedSpecies: Species?
    @Published var isIdentifying = false
    @Published var isCreatingSighting = false
    @Published var errorMessage: String?
    @Published var currentLocation: CLLocation?
    @Published var isPrivate = false
    
    private let apiClient = APIClient.shared
    private let locationManager = CLLocationManager()
    
    init() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func captureImage(_ image: UIImage) {
        capturedImage = image
        identifyImage(image)
    }
    
    func identifyImage(_ image: UIImage) {
        isIdentifying = true
        errorMessage = nil
        
        Task {
            do {
                let candidates = try await apiClient.identifyPhoto(image: image)
                identificationCandidates = candidates
            } catch {
                errorMessage = "Identification failed: \(error.localizedDescription)"
            }
            isIdentifying = false
        }
    }
    
    func selectSpecies(_ species: Species) {
        selectedSpecies = species
    }
    
    func createSighting() {
        guard let image = capturedImage,
              let species = selectedSpecies,
              let location = currentLocation else {
            errorMessage = "Missing required information"
            return
        }
        
        isCreatingSighting = true
        errorMessage = nil
        
        Task {
            do {
                let sighting = try await apiClient.createSighting(
                    speciesId: species.id,
                    lat: location.coordinate.latitude,
                    lon: location.coordinate.longitude,
                    isPrivate: isPrivate,
                    image: image
                )
                
                // Reset form
                capturedImage = nil
                identificationCandidates = []
                selectedSpecies = nil
                isPrivate = false
                
            } catch {
                errorMessage = "Failed to create sighting: \(error.localizedDescription)"
            }
            isCreatingSighting = false
        }
    }
}

extension SightingCreateViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location error: \(error.localizedDescription)"
    }
}

