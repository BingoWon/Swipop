//
//  CoverService.swift
//  Swipop
//
//  Service for capturing, cropping, and uploading work covers
//

import UIKit
import WebKit
import Supabase

actor CoverService {
    
    static let shared = CoverService()
    
    private let supabase = SupabaseService.shared.client
    private let bucket = "thumbnails"
    
    /// Aspect ratio constraints: 4:3 to 3:4
    private let minAspectRatio: CGFloat = 3.0 / 4.0  // 0.75 (portrait)
    private let maxAspectRatio: CGFloat = 4.0 / 3.0  // 1.33 (landscape)
    
    private init() {}
    
    // MARK: - Public API
    
    /// Capture screenshot from WKWebView, crop to valid ratio, upload to storage
    @MainActor
    func captureAndUpload(from webView: WKWebView, workId: UUID) async throws -> String {
        // 1. Capture screenshot
        let screenshot = try await captureScreenshot(from: webView)
        
        // 2. Crop to valid aspect ratio
        let cropped = Self.cropToValidRatio(screenshot)
        
        // 3. Upload to storage
        return try await upload(image: cropped, workId: workId)
    }
    
    /// Process uploaded image: crop to valid ratio and upload
    func processAndUpload(image: UIImage, workId: UUID) async throws -> String {
        // 1. Crop to valid aspect ratio
        let cropped = Self.cropToValidRatio(image)
        
        // 2. Upload to storage
        return try await upload(image: cropped, workId: workId)
    }
    
    // MARK: - Screenshot Capture
    
    @MainActor
    private func captureScreenshot(from webView: WKWebView) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            let config = WKSnapshotConfiguration()
            config.rect = webView.bounds
            
            webView.takeSnapshot(with: config) { image, error in
                if let error {
                    continuation.resume(throwing: CoverError.captureFailed(error))
                } else if let image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: CoverError.noImage)
                }
            }
        }
    }
    
    // MARK: - Aspect Ratio Cropping
    
    /// Crop image to valid aspect ratio (4:3 to 3:4) - Static for synchronous access
    static func cropToValidRatio(_ image: UIImage) -> UIImage {
        let minRatio: CGFloat = 3.0 / 4.0  // 0.75 (portrait)
        let maxRatio: CGFloat = 4.0 / 3.0  // 1.33 (landscape)
        
        let currentRatio = image.size.width / image.size.height
        
        // Already within valid range
        if currentRatio >= minRatio && currentRatio <= maxRatio {
            return image
        }
        
        let targetRatio: CGFloat
        if currentRatio < minRatio {
            // Too tall (portrait), crop to 3:4
            targetRatio = minRatio
        } else {
            // Too wide (landscape), crop to 4:3
            targetRatio = maxRatio
        }
        
        return cropToRatio(image, targetRatio: targetRatio)
    }
    
    private static func cropToRatio(_ image: UIImage, targetRatio: CGFloat) -> UIImage {
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
    
    // MARK: - Upload
    
    private func upload(image: UIImage, workId: UUID) async throws -> String {
        // Compress to JPEG
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw CoverError.compressionFailed
        }
        
        // Get user ID for path
        guard let userId = try? await supabase.auth.session.user.id else {
            throw CoverError.notAuthenticated
        }
        
        // Path: {userId}/{workId}.jpg
        let path = "\(userId.uuidString)/\(workId.uuidString).jpg"
        
        // Upload (upsert to replace existing)
        try await supabase.storage
            .from(bucket)
            .upload(
                path,
                data: data,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )
        
        // Return public URL
        let publicUrl = try supabase.storage
            .from(bucket)
            .getPublicURL(path: path)
        
        return publicUrl.absoluteString
    }
    
    // MARK: - Delete
    
    func delete(workId: UUID) async throws {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        let path = "\(userId.uuidString)/\(workId.uuidString).jpg"
        
        try await supabase.storage
            .from(bucket)
            .remove(paths: [path])
    }
    
    // MARK: - Errors
    
    enum CoverError: LocalizedError {
        case captureFailed(Error)
        case noImage
        case compressionFailed
        case notAuthenticated
        
        var errorDescription: String? {
            switch self {
            case .captureFailed(let error): "Failed to capture: \(error.localizedDescription)"
            case .noImage: "No image captured"
            case .compressionFailed: "Failed to compress image"
            case .notAuthenticated: "Please sign in"
            }
        }
    }
}

