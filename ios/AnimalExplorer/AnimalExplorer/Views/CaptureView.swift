import SwiftUI
import PhotosUI

struct CaptureView: View {
    @EnvironmentObject var viewModel: SightingCreateViewModel
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingSpeciesSelector = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                    
                    if viewModel.isIdentifying {
                        ProgressView("Identifying species...")
                            .padding()
                    } else if !viewModel.identificationCandidates.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Identification Results:")
                                .font(.headline)
                            
                            ForEach(viewModel.identificationCandidates, id: \.speciesId) { candidate in
                                Button(action: {
                                    // Handle species selection
                                    showingSpeciesSelector = true
                                }) {
                                    HStack {
                                        Text(candidate.label)
                                        Spacer()
                                        Text("\(Int(candidate.score * 100))%")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    if let selectedSpecies = viewModel.selectedSpecies {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Selected Species:")
                                .font(.headline)
                            
                            Text(selectedSpecies.commonName)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(selectedSpecies.scientificName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Toggle("Private Sighting", isOn: $viewModel.isPrivate)
                                .padding(.top)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        
                        Button("Create Sighting") {
                            viewModel.createSighting()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isCreatingSighting)
                    }
                    
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "camera")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Capture an animal sighting")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Take a photo to identify the species")
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            Button("Camera") {
                                showingCamera = true
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Photo Library") {
                                showingImagePicker = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Capture")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: Binding(
                    get: { viewModel.capturedImage },
                    set: { image in
                        if let image = image {
                            viewModel.captureImage(image)
                        }
                    }
                ))
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(image: Binding(
                    get: { viewModel.capturedImage },
                    set: { image in
                        if let image = image {
                            viewModel.captureImage(image)
                        }
                    }
                ))
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    CaptureView()
        .environmentObject(SightingCreateViewModel())
}

