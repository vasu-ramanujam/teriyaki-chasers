//
//  PostFlowView.swift
//  wildlifeFinder
//
//  Created by Owen Davis on 10/28/25.
//
import SwiftUI

struct PostFlowView: View {
    @State private var path = NavigationPath()
    @StateObject private var postVM = PostViewModel()
    
    var body: some View {
        NavigationStack(path: $path) {
            InitialView(postVM: postVM, path: $path)
                .navigationDestination(for: String.self) { value in
                    if value == "identify"{
                        IdentifyView(postVM: postVM, path: $path)
                    } else if value == "post" {
                        PostView(postVM: postVM, path: $path)
                    }
                }
        }
    }
}

struct InitialView: View {
    @StateObject var postVM: PostViewModel
    @Binding var path: NavigationPath
    @State private var showCamera = false
    @State private var showRecorder = false
    
    private let accentGreen = Color(red: 35/255.0, green: 86/255.0, blue: 61/255.0)
    private let accentOrange = Color(red: 241/255.0, green: 154/255.0, blue: 62/255.0)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("Add Sighting Media")
                    .font(.title2.bold())
                    .padding(.top, 32)
                
                // MARK: Photo section
                VStack(spacing: 16) {
                    ZStack(alignment: .topTrailing) {
                        Group {
                            if let image = postVM.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.gray.opacity(0.1))
                                    .overlay(
                                        VStack(spacing: 10) {
                                            Image(systemName: "photo")
                                                .font(.system(size: 36))
                                                .foregroundStyle(.secondary)
                                            Text("Add an Image")
                                                .font(.headline)
                                                .foregroundStyle(.secondary)
                                        }
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
                        
                        if postVM.image != nil {
                            Button("Retake?") { showCamera = true }
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.85))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .padding(12)
                        }
                    }
                    
                    Button {
                        showCamera = true
                    } label: {
                        Label(postVM.image == nil ? "Take Photo" : "Retake Photo",
                              systemImage: "camera")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accentGreen)
                }
                
                // MARK: Audio section
                VStack(spacing: 16) {
                    if let audioURL = postVM.audioURL {
                        AudioPlaybackView(url: audioURL)
                            .id(audioURL)
                            .padding()
                            .background(Color.gray.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 6)
                            .padding(.horizontal, 4)
                        
                        Button("Rerecord?") { showRecorder = true }
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.85))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 120)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "waveform")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.secondary)
                                    Text("No audio recorded")
                                        .foregroundStyle(.secondary)
                                }
                            )
                        Button {
                            showRecorder = true
                        } label: {
                            Label("Record a Sound", systemImage: "mic")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(accentGreen)
                    }
                }
                
                // MARK: Identify button
                Button {
                    path.append("identify")
                } label: {
                    Text("Identify")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(accentOrange)
                .disabled(postVM.image == nil && postVM.audioURL == nil)
                .opacity((postVM.image == nil && postVM.audioURL == nil) ? 0.4 : 1)
                
                Spacer(minLength: 60)
            }
            .padding(.horizontal, 24)
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { img in
                postVM.image = img
            }
        }
        .fullScreenCover(isPresented: $showRecorder) {
            AudioRecordingView { url in
                postVM.audioURL = url
            }
        }
    }
}

struct buttonBackground: View {
    var color: Color
    var cornerRad = 10.0
    var shadowRad = 5.0
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRad)
            .fill(color)
            .shadow(radius: shadowRad)
    }
}

struct IdentifyView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isLoading: Bool = false
    @StateObject var postVM: PostViewModel
    @Binding var path: NavigationPath

    var body: some View {
        VStack {
            HStack {
                Button("< Back") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .tint(.primary)
                Spacer()
            }
            .padding([.horizontal, .top])
            
            if isLoading {
                ProgressView("Identifying...")
                    .navigationBarBackButtonHidden(true)
            } else {
                if let animal = postVM.animal {
                    Text("You found: \(animal.common_name)!")
                        .font(.largeTitle) // Start with a large font size
                        .lineLimit(1) // Ensure the text stays on a single line
                        .minimumScaleFactor(0.1) // Allow scaling down to 10% of the original size
                        .frame(maxWidth: .infinity)
                        .padding(.leading)
                        .padding(.trailing)
                        .navigationBarBackButtonHidden(true)

                    SpeciesView(species: animal)
                    
                    NavigationLink("Post Sighting", value: "post")
                    .foregroundStyle(.black)
                    .padding()
                    .background(
                        buttonBackground(color: Color(red: 241/255.0, green: 154/255.0, blue: 62/255.0)),
                        alignment: .center
                    )
                } else {
                    Text("There should be an animal lol")
                }
                
            }
        }
        .onAppear {
            Task {
                isLoading = true
                defer { isLoading = false }
                do {
                    if let image = postVM.image, let data = image.jpegData(compressionQuality: 0.85) {
                        let result = try await APIService.shared.identifyPhoto(imageData: data)
                        if let speciesId = result.species_id {
                            let species = try await APIService.shared.getSpecies(id: speciesId)
                            postVM.animal = Species(from: species)
                            postVM.speciesId = speciesId
                        } else {
                            let matches = try await APIService.shared.searchSpecies(query: result.label, limit: 1)
                            if let s = matches.first {
                                postVM.animal = Species(from: s)
                                postVM.speciesId = s.id
                            }
                        }
                    } else if let audioURL = postVM.audioURL {
                        let data = try Data(contentsOf: audioURL)
                        let result = try await APIService.shared.identifyAudio(audioData: data)
                        if let speciesId = result.species_id {
                            let species = try await APIService.shared.getSpecies(id: speciesId)
                            postVM.animal = Species(from: species)
                            postVM.speciesId = speciesId
                        } else {
                            let matches = try await APIService.shared.searchSpecies(query: result.label, limit: 1)
                            if let s = matches.first {
                                postVM.animal = Species(from: s)
                                postVM.speciesId = s.id
                            }
                        }
                    }
                } catch {
                    print("Identify error: \(error)")
                }
            }
            
        }
    }
}

struct PostView: View {
    @StateObject var postVM: PostViewModel
    @Binding var path: NavigationPath
    @State private var isPosting = false
    @State private var postError: String?

    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                if let image = postVM.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 6)
                        .padding(.trailing)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .padding(.trailing)
                }
            
                Button {
                    postVM.image = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }
            .padding()
            
            ZStack(alignment: .topTrailing) {
                Text("Audio bar here")
                    .padding(.trailing)
                
                Button {
                    postVM.audioURL = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }
            .padding()
            
            VStack(alignment: .leading) {
                Text("Enter caption...")
                
                TextField("Caption", text: $postVM.caption)
                    .frame(height: 50)
                    .padding(.leading)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 2)
                    )
            }
            .containerRelativeFrame(.horizontal) { size, axis in
                size * 0.8
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.gray)
                    .opacity(0.2)
            )
            
            VStack(alignment: .leading) {
                Text("Visibility:")
                
                HStack {
                    Text("Anonymous")
                    
                    Toggle("", isOn: $postVM.isPublic)
                        .labelsHidden()
                    
                    Text("Public")
                }
                .containerRelativeFrame(.horizontal) { size, axis in
                    size * 0.8
                }
            }
            .containerRelativeFrame(.horizontal) { size, axis in
                size * 0.8
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.gray)
                    .opacity(0.2)
            )
            
            Button {
                Task { await postSighting() }
            } label: {
                Text("Post")
                    .foregroundStyle(.black)
                    .padding()
                    .background(
                        buttonBackground(color: Color(red: 241/255.0, green: 154/255.0, blue: 62/255.0)),
                        alignment: .center
                    )
            }
            .disabled(isPosting || postVM.image == nil || postVM.speciesId == nil)
        }
        .alert("Post failed", isPresented: .constant(postError != nil)) {
            Button("OK") { postError = nil }
        } message: {
            Text(postError ?? "")
        }
    }
}

extension PostView {
    func postSighting() async {
        guard let image = postVM.image, let jpeg = image.jpegData(compressionQuality: 0.9) else { return }
        guard let speciesId = postVM.speciesId else { return }
        isPosting = true
        defer { isPosting = false }

        let coord = LocationManagerViewModel.shared.coordinate
        do {
            _ = try await APIService.shared.createSighting(
                speciesId: speciesId,
                coordinate: coord,
                isPublic: postVM.isPublic,
                caption: postVM.caption,
                username: nil,
                imageJPEGData: jpeg
            )

            // reset the view model
            postVM.image = nil
            postVM.audioURL = nil
            postVM.speciesId = nil
            postVM.animal = nil
            postVM.caption = ""
            postVM.isPublic = false

            // return to start
            path.removeLast(path.count)
        } catch {
            postError = error.localizedDescription
        }
    }
}
