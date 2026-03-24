import SwiftUI

struct PhotoGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var showControls = true
    @State private var showDeleteAlert = false

    let photoIds: [String]
    var onDelete: ((String) -> Void)?

    private let photoService = PhotoService.shared

    init(photoIds: [String], initialIndex: Int = 0, onDelete: ((String) -> Void)? = nil) {
        self.photoIds = photoIds
        self._currentIndex = State(initialValue: initialIndex)
        self.onDelete = onDelete
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Photo pager
            TabView(selection: $currentIndex) {
                ForEach(Array(photoIds.enumerated()), id: \.offset) { index, photoId in
                    ZoomablePhotoView(photoId: photoId) {
                        withAnimation {
                            showControls.toggle()
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Controls overlay
            VStack {
                // Top bar
                if showControls {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5), in: Circle())
                        }

                        Spacer()

                        Text("\(currentIndex + 1) / \(photoIds.count)")
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.5), in: Capsule())

                        Spacer()

                        if onDelete != nil {
                            Button {
                                showDeleteAlert = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.5), in: Circle())
                            }
                        } else {
                            Color.clear.frame(width: 44, height: 44)
                        }
                    }
                    .padding()
                    .transition(.opacity)
                }

                Spacer()

                // Page indicator
                if showControls && photoIds.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<photoIds.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                                .frame(width: index == currentIndex ? 8 : 6, height: index == currentIndex ? 8 : 6)
                        }
                    }
                    .padding(.bottom, 32)
                    .transition(.opacity)
                }
            }
        }
        .alert("Delete Photo", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let onDelete = onDelete {
                    onDelete(photoIds[currentIndex])
                    if photoIds.count == 1 {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this photo?")
        }
        .statusBarHidden(true)
    }
}

// MARK: - Zoomable Photo View

struct ZoomablePhotoView: View {
    let photoId: String
    let onTap: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let photoService = PhotoService.shared

    var body: some View {
        GeometryReader { geometry in
            if let image = photoService.loadPhoto(photoId: photoId) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded {
                                withAnimation {
                                    if scale > 1 {
                                        scale = 1
                                        offset = .zero
                                    } else {
                                        scale = 2.5
                                    }
                                }
                            }
                    )
                    .gesture(
                        TapGesture(count: 1)
                            .onEnded { onTap() }
                    )
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let newScale = lastScale * value
                                scale = min(max(newScale, 1), 5)
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale <= 1 {
                                    withAnimation {
                                        offset = .zero
                                    }
                                    lastOffset = .zero
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                if scale > 1 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                ProgressView()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

// MARK: - Photo Thumbnail Grid

struct PhotoThumbnailGrid: View {
    let photoIds: [String]
    let onPhotoTap: (Int) -> Void
    var onAddTap: (() -> Void)?

    private let photoService = PhotoService.shared
    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            // Add button
            if let onAddTap = onAddTap {
                Button(action: onAddTap) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .aspectRatio(1, contentMode: .fill)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                }
            }

            // Photo thumbnails
            ForEach(Array(photoIds.enumerated()), id: \.offset) { index, photoId in
                Button {
                    onPhotoTap(index)
                } label: {
                    if let thumbnail = photoService.loadThumbnail(photoId: photoId) {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .aspectRatio(1, contentMode: .fill)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundColor(.secondary)
                            }
                    }
                }
            }
        }
        .padding(4)
    }
}

// MARK: - Photo Preview Row

struct PhotoPreviewRow: View {
    let photoIds: [String]
    let maxDisplay: Int
    let onPhotoTap: (Int) -> Void
    let onViewAllTap: () -> Void

    private let photoService = PhotoService.shared

    init(
        photoIds: [String],
        maxDisplay: Int = 4,
        onPhotoTap: @escaping (Int) -> Void,
        onViewAllTap: @escaping () -> Void
    ) {
        self.photoIds = photoIds
        self.maxDisplay = maxDisplay
        self.onPhotoTap = onPhotoTap
        self.onViewAllTap = onViewAllTap
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(photoIds.prefix(maxDisplay).enumerated()), id: \.offset) { index, photoId in
                Button {
                    onPhotoTap(index)
                } label: {
                    ZStack {
                        if let thumbnail = photoService.loadThumbnail(photoId: photoId) {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(width: 64, height: 64)
                        }

                        // Show remaining count on last item
                        if index == maxDisplay - 1 && photoIds.count > maxDisplay {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 64, height: 64)

                            Text("+\(photoIds.count - maxDisplay)")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
            }

            if photoIds.count > maxDisplay {
                Button("View all", action: onViewAllTap)
            }
        }
    }
}

#Preview {
    PhotoGalleryView(photoIds: ["test1", "test2", "test3"])
}
