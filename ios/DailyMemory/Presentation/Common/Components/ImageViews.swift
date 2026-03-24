import SwiftUI

// MARK: - Cached Async Image
/// Async image with loading and error states
struct CachedAsyncImage<Placeholder: View, ErrorView: View>: View {
    let url: URL?
    let contentMode: ContentMode
    @ViewBuilder let placeholder: () -> Placeholder
    @ViewBuilder let errorView: () -> ErrorView

    init(
        url: URL?,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder errorView: @escaping () -> ErrorView
    ) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder
        self.errorView = errorView
    }

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                placeholder()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure:
                errorView()
            @unknown default:
                placeholder()
            }
        }
    }
}

// MARK: - Convenience initializer with defaults
extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView>, ErrorView == ImagePlaceholder {
    init(url: URL?, contentMode: ContentMode = .fill) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = { ProgressView() }
        self.errorView = { ImagePlaceholder() }
    }

    init(urlString: String?, contentMode: ContentMode = .fill) {
        self.url = urlString.flatMap { URL(string: $0) }
        self.contentMode = contentMode
        self.placeholder = { ProgressView() }
        self.errorView = { ImagePlaceholder() }
    }
}

// MARK: - Image Placeholder
struct ImagePlaceholder: View {
    var icon: String = "photo"
    var backgroundColor: Color = Color(.systemGray5)
    var iconColor: Color = .secondary

    var body: some View {
        ZStack {
            backgroundColor
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor.opacity(0.5))
        }
    }
}

// MARK: - Avatar Image
struct AvatarImage: View {
    let imageUrl: String?
    let name: String?
    var size: CGFloat = 48
    var backgroundColor: Color = Color(.systemGray5)

    private var initials: String {
        guard let name = name else { return "?" }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var body: some View {
        if let urlString = imageUrl, let url = URL(string: urlString) {
            CachedAsyncImage(url: url) {
                initialsView
            } errorView: {
                initialsView
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            initialsView
        }
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)

            Image(systemName: "person.fill")
                .font(.system(size: size * 0.4))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Photo Thumbnail
struct PhotoThumbnail: View {
    let url: String?
    var size: CGFloat = 80
    var cornerRadius: CGFloat = 12

    var body: some View {
        Group {
            if let urlString = url, let imageUrl = URL(string: urlString) {
                CachedAsyncImage(url: imageUrl) {
                    ImagePlaceholder()
                } errorView: {
                    ImagePlaceholder(icon: "photo.badge.exclamationmark")
                }
            } else {
                ImagePlaceholder()
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Photo Grid
struct PhotoGrid: View {
    let urls: [String]
    var maxDisplay: Int = 4
    var size: CGFloat = 80
    var spacing: CGFloat = 8

    var body: some View {
        let displayUrls = Array(urls.prefix(maxDisplay))
        let remainingCount = urls.count - maxDisplay

        HStack(spacing: spacing) {
            ForEach(displayUrls.indices, id: \.self) { index in
                if index == maxDisplay - 1 && remainingCount > 0 {
                    // Show remaining count overlay
                    ZStack {
                        PhotoThumbnail(url: displayUrls[index], size: size)
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.5))
                        Text("+\(remainingCount + 1)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(width: size, height: size)
                } else {
                    PhotoThumbnail(url: displayUrls[index], size: size)
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("Avatar") {
    HStack(spacing: 16) {
        AvatarImage(imageUrl: nil, name: "John Doe")
        AvatarImage(imageUrl: nil, name: "Jane", size: 64)
        AvatarImage(imageUrl: "https://example.com/photo.jpg", name: "Test")
    }
    .padding()
}

#Preview("Photo Grid") {
    PhotoGrid(urls: [
        "https://example.com/1.jpg",
        "https://example.com/2.jpg",
        "https://example.com/3.jpg",
        "https://example.com/4.jpg",
        "https://example.com/5.jpg"
    ])
    .padding()
}
