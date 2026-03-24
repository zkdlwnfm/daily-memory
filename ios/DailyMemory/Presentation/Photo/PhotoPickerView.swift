import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PhotoPickerViewModel()

    let maxPhotos: Int
    let onPhotosSelected: ([String]) -> Void

    init(maxPhotos: Int = 10, onPhotosSelected: @escaping ([String]) -> Void) {
        self.maxPhotos = maxPhotos
        self.onPhotosSelected = onPhotosSelected
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Source selection buttons
                HStack(spacing: 12) {
                    Button {
                        viewModel.showCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)

                    PhotosPicker(
                        selection: $viewModel.selectedItems,
                        maxSelectionCount: maxPhotos,
                        matching: .images
                    ) {
                        Label("Gallery", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()

                Divider()

                // Selected photos
                if viewModel.selectedPhotos.isEmpty {
                    emptyStateView
                } else {
                    selectedPhotosGrid
                }
            }
            .navigationTitle(viewModel.selectedPhotos.isEmpty ? "Add Photos" : "\(viewModel.selectedPhotos.count) selected")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.selectedPhotos.isEmpty {
                        Button("Done") {
                            viewModel.saveSelectedPhotos { photoIds in
                                onPhotosSelected(photoIds)
                                dismiss()
                            }
                        }
                        .disabled(viewModel.isSaving)
                    }
                }
            }
            .overlay {
                if viewModel.isSaving {
                    savingOverlay
                }
            }
            .sheet(isPresented: $viewModel.showCamera) {
                CameraView { image in
                    viewModel.addPhoto(image)
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onChange(of: viewModel.selectedItems) { newItems in
                viewModel.loadPhotos(from: newItems)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No photos selected")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Take a photo or choose from gallery")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var selectedPhotosGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4)
            ], spacing: 4) {
                ForEach(viewModel.selectedPhotos) { photo in
                    SelectedPhotoCell(
                        image: photo.image,
                        onRemove: { viewModel.removePhoto(photo) }
                    )
                }
            }
            .padding(8)
        }
    }

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Saving photos...")
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

private struct SelectedPhotoCell: View {
    let image: UIImage
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fill)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white, Color.black.opacity(0.6))
            }
            .padding(4)
        }
    }
}

// MARK: - ViewModel

@MainActor
class PhotoPickerViewModel: ObservableObject {
    @Published var selectedItems: [PhotosPickerItem] = []
    @Published var selectedPhotos: [SelectedPhoto] = []
    @Published var showCamera = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let photoService = PhotoService.shared

    struct SelectedPhoto: Identifiable {
        let id = UUID()
        let image: UIImage
    }

    func loadPhotos(from items: [PhotosPickerItem]) {
        Task {
            var newPhotos: [SelectedPhoto] = []

            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    newPhotos.append(SelectedPhoto(image: image))
                }
            }

            selectedPhotos = newPhotos
        }
    }

    func addPhoto(_ image: UIImage) {
        selectedPhotos.append(SelectedPhoto(image: image))
    }

    func removePhoto(_ photo: SelectedPhoto) {
        selectedPhotos.removeAll { $0.id == photo.id }
    }

    func saveSelectedPhotos(completion: @escaping ([String]) -> Void) {
        isSaving = true

        Task {
            var photoIds: [String] = []

            for photo in selectedPhotos {
                let result = await photoService.savePhoto(image: photo.image)
                switch result {
                case .success(let savedPhoto):
                    photoIds.append(savedPhoto.id)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }

            isSaving = false
            completion(photoIds)
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
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
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    PhotoPickerView { photoIds in
        print("Selected: \(photoIds)")
    }
}
