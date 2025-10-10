import SwiftUI

struct ProfileView: View {
    @State private var userSightings: [Sighting] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading profile...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Profile header
                            VStack(spacing: 12) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.blue)
                                
                                Text("Animal Explorer")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text("Wildlife enthusiast")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            
                            // Stats
                            HStack(spacing: 20) {
                                StatCard(title: "Sightings", value: "\(userSightings.count)")
                                StatCard(title: "Species", value: "12")
                                StatCard(title: "XP", value: "1,250")
                            }
                            
                            // Recent sightings
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Sightings")
                                    .font(.headline)
                                
                                if userSightings.isEmpty {
                                    Text("No sightings yet")
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding()
                                } else {
                                    ForEach(userSightings.prefix(5)) { sighting in
                                        SightingRow(sighting: sighting)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                loadUserSightings()
            }
        }
    }
    
    private func loadUserSightings() {
        isLoading = true
        // In a real app, you'd load user-specific sightings
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            userSightings = []
            isLoading = false
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

struct SightingRow: View {
    let sighting: Sighting
    
    var body: some View {
        HStack {
            Image(systemName: "pawprint.fill")
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Species Name") // Would be actual species name
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(sighting.takenAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if sighting.isPrivate {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProfileView()
}

