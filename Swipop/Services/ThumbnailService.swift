//
//  ThumbnailService.swift
//  Swipop
//
//  Service for capturing, cropping, and uploading project thumbnails
//

import Supabase
import UIKit
import WebKit

/// Result of thumbnail upload: URL and aspect ratio
struct ThumbnailUploadResult {
    let url: String
    let aspectRatio: CGFloat // width / height
}

/// Thumbnail aspect ratio presets
enum ThumbnailAspectRatio: String, CaseIterable, Identifiable {
    case portrait = "3:4"
    case square = "1:1"
    case landscape = "4:3"

    var id: String { rawValue }

    var ratio: CGFloat {
        switch self {
        case .portrait: return 3.0 / 4.0
        case .square: return 1.0
        case .landscape: return 4.0 / 3.0
        }
    }

    var icon: String {
        switch self {
        case .portrait: return "rectangle.portrait"
        case .square: return "square"
        case .landscape: return "rectangle"
        }
    }
}

actor ThumbnailService {
    static let shared = ThumbnailService()

    private let supabase = SupabaseService.shared.client
    private let bucket = "thumbnails"

    private init() {}

    // MARK: - Public API

    /// Capture screenshot from WKWebView with specified aspect ratio
    @MainActor
    func capture(from webView: WKWebView, aspectRatio: ThumbnailAspectRatio) async throws -> UIImage {
        let screenshot = try await captureScreenshot(from: webView)
        return Self.cropToRatio(screenshot, targetRatio: aspectRatio.ratio)
    }

    /// Process and upload image to storage
    func upload(image: UIImage, projectId: UUID) async throws -> ThumbnailUploadResult {
        let cropped = Self.cropToValidRatio(image)
        let aspectRatio = cropped.size.width / cropped.size.height
        let url = try await uploadToStorage(image: cropped, projectId: projectId)
        return ThumbnailUploadResult(url: url, aspectRatio: aspectRatio)
    }

    /// Delete thumbnail from storage
    func delete(projectId: UUID) async throws {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        let path = "\(userId.uuidString)/\(projectId.uuidString).jpg"
        try await supabase.storage.from(bucket).remove(paths: [path])
    }

    // MARK: - Screenshot Capture

    @MainActor
    private func captureScreenshot(from webView: WKWebView) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            let config = WKSnapshotConfiguration()
            config.rect = webView.bounds

            webView.takeSnapshot(with: config) { image, error in
                if let error {
                    continuation.resume(throwing: ThumbnailError.captureFailed(error))
                } else if let image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: ThumbnailError.noImage)
                }
            }
        }
    }

    // MARK: - Aspect Ratio Cropping

    /// Crop image to valid aspect ratio (3:4 to 4:3) - Static for synchronous access
    static func cropToValidRatio(_ image: UIImage) -> UIImage {
        let minRatio: CGFloat = 3.0 / 4.0 // 0.75 (portrait)
        let maxRatio: CGFloat = 4.0 / 3.0 // 1.33 (landscape)
        let currentRatio = image.size.width / image.size.height

        // Already within valid range
        if currentRatio >= minRatio && currentRatio <= maxRatio {
            return image
        }

        let targetRatio = currentRatio < minRatio ? minRatio : maxRatio
        return cropToRatio(image, targetRatio: targetRatio)
    }

    static func cropToRatio(_ image: UIImage, targetRatio: CGFloat) -> UIImage {
        let originalSize = image.size
        let originalRatio = originalSize.width / originalSize.height

        var cropRect: CGRect

        if originalRatio > targetRatio {
            // Image is wider than target, crop horizontally (center crop)
            let newWidth = originalSize.height * targetRatio
            let xOffset = (originalSize.width - newWidth) / 2
            cropRect = CGRect(x: xOffset, y: 0, width: newWidth, height: originalSize.height)
        } else {
            // Image is taller than target, crop vertically (center crop)
            let newHeight = originalSize.width / targetRatio
            let yOffset = (originalSize.height - newHeight) / 2
            cropRect = CGRect(x: 0, y: yOffset, width: originalSize.width, height: newHeight)
        }

        // Handle scale
        cropRect = CGRect(
            x: cropRect.origin.x * image.scale,
            y: cropRect.origin.y * image.scale,
            width: cropRect.width * image.scale,
            height: cropRect.height * image.scale
        )

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Storage Upload

    private func uploadToStorage(image: UIImage, projectId: UUID) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ThumbnailError.compressionFailed
        }

        guard let userId = try? await supabase.auth.session.user.id else {
            throw ThumbnailError.notAuthenticated
        }

        let path = "\(userId.uuidString)/\(projectId.uuidString).jpg"

        try await supabase.storage
            .from(bucket)
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))

        return try supabase.storage.from(bucket).getPublicURL(path: path).absoluteString
    }

    // MARK: - Errors

    enum ThumbnailError: LocalizedError {
        case captureFailed(Error)
        case noImage
        case compressionFailed
        case notAuthenticated

        var errorDescription: String? {
            switch self {
            case let .captureFailed(error): "Failed to capture: \(error.localizedDescription)"
            case .noImage: "No image captured"
            case .compressionFailed: "Failed to compress image"
            case .notAuthenticated: "Please sign in"
            }
        }
    }
}
