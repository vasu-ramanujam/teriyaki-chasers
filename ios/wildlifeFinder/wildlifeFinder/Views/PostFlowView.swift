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
    
    var body: some View {
        VStack {
            // Display image
            if let image = postVM.image {
                Text("Image goes here")
            }
            
            // Add an image
            Button {
                // Hook to taking the picture
            } label: {
                Image(systemName: "camera")
                    .foregroundStyle(.white)
                Text(postVM.image != nil ? "Retake Photo" : "Take Photo")
                    .foregroundStyle(.white)
            }
            .padding()
            .background(
                buttonBackground(color: Color(red: 35/255.0, green: 86/255.0, blue: 61/255.0)),
                alignment: .center
            )
            .padding(.bottom)

            // Display image
            if let sound = postVM.audioURL {
                Text("Sound goes here")
            }
            
            // Add a sound
            Button {
                // Hook to recording sound
                
                // This is here as a placeholder so I can advance to the next page
                postVM.audioURL = URL(string: "https://en.wikipedia.org/wiki/American_red_squirrel")
            } label: {
                Image(systemName: "mic")
                    .foregroundStyle(.white)
                Text(postVM.audioURL != nil ? "Rerecord Audio" : "Record Audio")
                    .foregroundStyle(.white)
            }
            .padding()
            .background(
                buttonBackground(color: Color(red: 35/255.0, green: 86/255.0, blue: 61/255.0)),
                alignment: .center
            )
            .padding(.bottom)

            if postVM.image != nil || postVM.audioURL != nil {
                // Identify the sighting
                NavigationLink("Identify", value: "identify")
                .foregroundStyle(.black)
                .padding()
                .background(
                    buttonBackground(color: Color(red: 241/255.0, green: 154/255.0, blue: 62/255.0)),
                    alignment: .center
                )
            }
        }
        .scaleEffect(1.5)
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
    @State private var isLoading: Bool = false
    @StateObject var postVM: PostViewModel
    @Binding var path: NavigationPath

    var body: some View {
        VStack {
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
                if postVM.animal == nil {
                    isLoading = true
                    // call the identification API
                    
                    // this is mock data for now
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    postVM.animal = MockSpecies.squirrel
                    
                    isLoading = false
                }
            }
            
        }
    }
}

struct PostView: View {
    @StateObject var postVM: PostViewModel
    @Binding var path: NavigationPath

    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                if let image = postVM.image {
                    Image(uiImage: image)
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
                // make API call to post details
                
                // reset the view model
                postVM.image = nil
                postVM.audioURL = nil
                postVM.speciesId = nil
                postVM.animal = nil
                
                // return to start
                path.removeLast(path.count)
            } label: {
                Text("Post")
                    .foregroundStyle(.black)
                    .padding()
                    .background(
                        buttonBackground(color: Color(red: 241/255.0, green: 154/255.0, blue: 62/255.0)),
                        alignment: .center
                    )
            }
        }
    }
}
