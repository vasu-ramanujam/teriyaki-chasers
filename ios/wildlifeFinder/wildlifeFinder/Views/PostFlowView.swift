//
//  PostFlowView.swift
//  wildlifeFinder
//
//  Created by Owen Davis on 10/28/25.
//
import SwiftUI

struct PostFlowView: View {
    var body: some View {
        NavigationStack {
            InitialView()
        }
    }
}

struct InitialView: View {
    @State var image: UIImage? = nil
    @State var audioURL: URL? = nil
    
    var body: some View {
        VStack {
            // Display image
            if let image = image {
                Text("Image goes here")
            }
            
            // Add an image
            Button {
                // Hook to taking the picture
            } label: {
                Image(systemName: "camera")
                    .foregroundStyle(.white)
                Text(image != nil ? "Retake Photo" : "Take Photo")
                    .foregroundStyle(.white)
            }
            .padding()
            .background(
                buttonBackground(color: Color(red: 35/255.0, green: 86/255.0, blue: 61/255.0)),
                alignment: .center
            )
            .padding(.bottom)

            // Display image
            if let sound = audioURL {
                Text("Sound goes here")
            }
            
            // Add a sound
            Button {
                // Hook to recording sound
            } label: {
                Image(systemName: "mic")
                    .foregroundStyle(.white)
                Text(audioURL != nil ? "Rerecord Audio" : "Record Audio")
                    .foregroundStyle(.white)
            }
            .padding()
            .background(
                buttonBackground(color: Color(red: 35/255.0, green: 86/255.0, blue: 61/255.0)),
                alignment: .center
            )
            .padding(.bottom)

            if image != nil || audioURL != nil {
                // Identify the sighting
                Button {
                    // Hook to Identify page
                } label: {
                    Text("Identify")
                        .foregroundStyle(.black)
                }
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
