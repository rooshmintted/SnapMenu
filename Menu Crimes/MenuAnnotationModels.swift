//
//  MenuAnnotationModels.swift
//  Menu Crimes
//
//  Data models for menu annotation functionality using Vision Framework for text detection
//

import Foundation
import SwiftUI
import Vision
import UIKit

// MARK: - Error Types
enum MenuAnnotationError: Error, LocalizedError {
    case visionProcessingFailed
    case imageProcessingFailed
    case noTextDetected
    
    var errorDescription: String? {
        switch self {
        case .visionProcessingFailed:
            return "Failed to process image with Vision Framework"
        case .imageProcessingFailed:
            return "Failed to process image data"
        case .noTextDetected:
            return "No text was detected in the image"
        }
    }
}

// MARK: - Detected Text Region
struct DetectedTextRegion {
    let text: String
    let boundingBox: CGRect
    let confidence: Float
}

// MARK: - Menu Annotation Manager
@Observable
final class MenuAnnotationManager {
    var isLoading = false
    var error: String?
    var menuAnalysisData: MenuAnalysisResponse?
    var annotatedImageData: Data?
    var originalImage: UIImage? // Store the provided image for annotation
    
    // MARK: - Data Loading Methods
    
    /// Set analysis data and image directly from live analysis results
    func setAnalysisData(_ response: MenuAnalysisResponse, image: UIImage) {
        print("📊 MenuAnnotationManager: Setting live analysis data with \(response.dishes_found) dishes")
        self.menuAnalysisData = response
        self.originalImage = image
        
        // Debug: Log the provided image properties
        print("📊 MenuAnnotationManager: Stored original image")
        print("   Image size: \(image.size)")
        print("   Image scale: \(image.scale)")
        print("   Image actual pixel size: \(image.size.width * image.scale) x \(image.size.height * image.scale)")
        
        // Reset previous annotation state
        annotatedImageData = nil
        error = nil
        
        print("📊 MenuAnnotationManager: Ready for annotation generation with dishes:")
        for dish in response.analysis.dishes {
            print("   - '\(dish.dishName)' (\(dish.marginPercentage)%)")
        }
    }
    
    // Load menu analysis data from JSON file
    func loadMenuAnalysis() {
        guard let path = Bundle.main.path(forResource: "menu_items", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            error = "Failed to load menu_items.json file"
            return
        }
        
        do {
            menuAnalysisData = try JSONDecoder().decode(MenuAnalysisResponse.self, from: data)
            print("📊 MenuAnnotationManager: Loaded \(menuAnalysisData?.dishes_found ?? 0) dishes for annotation")
        } catch {
            self.error = "Failed to parse menu data: \(error.localizedDescription)"
            print("❌ MenuAnnotationManager: JSON parsing error - \(error)")
        }
    }
    
    // Generate annotated image with Vision-based text detection
    func generateAnnotatedImage() async {
        print("🎯 Starting annotation generation with Vision Framework...")
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        guard let analysisData = menuAnalysisData else {
            await MainActor.run {
                error = "No menu analysis data available"
                isLoading = false
            }
            return
        }
        
        // Try to load the image from the live analysis data or fall back to bundle
        var baseImage: UIImage?
        
        // Use the stored original image if available, otherwise fall back to bundle
        if let storedImage = originalImage {
            baseImage = storedImage
            print("📊 MenuAnnotationManager: Using stored original image")
        } else if let imagePath = Bundle.main.path(forResource: "Sears-Menu-Breakfast-1", ofType: "jpg") {
            baseImage = UIImage(contentsOfFile: imagePath)
            print("📊 MenuAnnotationManager: Using fallback bundle image")
        }
        
        guard let baseImage = baseImage else {
            await MainActor.run {
                error = "Failed to load menu image"
                isLoading = false
            }
            return
        }
        
        // Debug: Log the loaded image properties for size consistency tracking
        print("📊 MenuAnnotationManager: Loaded base image")
        print("   Base image size: \(baseImage.size)")
        print("   Base image scale: \(baseImage.scale)")
        print("   Base image actual pixel size: \(baseImage.size.width * baseImage.scale) x \(baseImage.size.height * baseImage.scale)")
        
        // Step 1: Detect text regions using Vision Framework
        print("🔍 MenuAnnotationManager: Starting text detection using Vision Framework...")
        
        do {
            let detectedTextRegions = try await detectTextRegions(in: baseImage)
            print("🔍 MenuAnnotationManager: Detected \(detectedTextRegions.count) text regions")
            
            // Step 2: Match dish names from JSON with detected text
            let matchedDishes = matchDishesWithDetectedText(
                dishes: analysisData.analysis.dishes,
                detectedRegions: detectedTextRegions
            )
            print("📊 MenuAnnotationManager: Matched \(matchedDishes.count) dishes with detected text")
            
            // Step 3: Create annotated image
            let annotatedImage = createAnnotatedImage(
                baseImage: baseImage,
                matchedDishes: matchedDishes
            )
            
            await MainActor.run {
                annotatedImageData = annotatedImage.jpegData(compressionQuality: 0.9)
                isLoading = false
                print("📊 MenuAnnotationManager: Generated annotated image with \(matchedDishes.count) annotations")
            }
            
        } catch {
            await MainActor.run {
                self.error = "Text detection failed: \(error.localizedDescription)"
                isLoading = false
                print("❌ MenuAnnotationManager: Text detection error - \(error)")
            }
        }
    }
    
    /// Generate annotations directly for selected dishes
    /// - Parameters:
    ///   - dishes: Array of selected DishAnalysis objects
    ///   - image: Original menu image
    /// - Returns: Annotated UIImage with bounding boxes and margin badges
    func generateAnnotations(for dishes: [DishAnalysis], image: UIImage) async -> UIImage? {
        print("🎯 Starting direct annotation generation for \(dishes.count) selected dishes...")
        
        // Create temporary MenuAnalysisResponse for selected dishes
        let tempAnalysis = AnalysisData(
            dishes: dishes,
            overall_notes: "Direct annotation generation"
        )
        
        let tempResponse = MenuAnalysisResponse(
            success: true,
            analysis: tempAnalysis,
            dishes_found: dishes.count
        )
        
        // Set the data temporarily
        self.setAnalysisData(tempResponse, image: image)
        
        // Generate the annotated image
        await generateAnnotatedImage()
        
        // Return the generated image data as UIImage
        if let imageData = annotatedImageData {
            return UIImage(data: imageData)
        }
        
        return nil
    }
    
    // MARK: - Text Detection using Vision Framework
    private func detectTextRegions(in image: UIImage) async throws -> [DetectedTextRegion] {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: MenuAnnotationError.visionProcessingFailed)
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    print("❌ Vision text detection error: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    print("❌ No text observations found")
                    continuation.resume(returning: [])
                    return
                }
                
                print("🔍 Vision detected \(observations.count) text regions")
                
                var detectedRegions: [DetectedTextRegion] = []
                
                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    
                    let text = candidate.string
                    let confidence = candidate.confidence
                    
                    // Convert Vision coordinates (normalized, bottom-left origin) to UIImage coordinates (top-left origin)
                    let visionBounds = observation.boundingBox
                    
                    // Convert normalized coordinates directly to UIImage coordinate space
                    let imageSize = image.size
                    let x = visionBounds.origin.x * imageSize.width
                    let y = (1 - visionBounds.origin.y - visionBounds.height) * imageSize.height  // Flip Y-axis for UIKit
                    let width = visionBounds.size.width * imageSize.width
                    let height = visionBounds.size.height * imageSize.height
                    
                    let convertedBounds = CGRect(x: x, y: y, width: width, height: height)
                    
                    let region = DetectedTextRegion(
                        text: text,
                        boundingBox: convertedBounds,
                        confidence: confidence
                    )
                    
                    detectedRegions.append(region)
                    
                    print("📍 Detected: '\(text)' at Vision coords: \(visionBounds) → UIImage coords: \(convertedBounds)")
                    print("   Image size used for conversion: \(imageSize)")
                }
                
                continuation.resume(returning: detectedRegions)
            }
            
            // Configure text recognition for better accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            
            // Pass the image orientation to Vision so it detects in the same coordinate system as UIImage drawing
            let orientation = cgImagePropertyOrientation(from: image.imageOrientation)
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("❌ Vision request failed: \(error)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Dish Matching Logic
    private func matchDishesWithDetectedText(
        dishes: [DishAnalysis],
        detectedRegions: [DetectedTextRegion]
    ) -> [(dish: DishAnalysis, textRegion: DetectedTextRegion)] {
        var matchedDishes: [(dish: DishAnalysis, textRegion: DetectedTextRegion)] = []
        
        for dish in dishes {
            let dishName = dish.dishName.lowercased()
            print("🔍 Looking for dish: '\(dishName)'")
            
            // Find the best matching text region for this dish
            let bestMatch = findBestTextMatch(for: dishName, in: detectedRegions)
            
            if let match = bestMatch {
                matchedDishes.append((dish: dish, textRegion: match))
                print("✅ Matched '\(dish.dishName)' with detected text '\(match.text)' (confidence: \(match.confidence))")
            } else {
                print("❌ No match found for dish: '\(dish.dishName)'")
            }
        }
        
        return matchedDishes
    }
    
    // Find the best text match for a dish name
    private func findBestTextMatch(for dishName: String, in detectedRegions: [DetectedTextRegion]) -> DetectedTextRegion? {
        var bestMatch: DetectedTextRegion?
        var bestScore: Double = 0.0
        
        for region in detectedRegions {
            let detectedText = region.text.lowercased()
            
            // Calculate similarity score using multiple strategies
            let score = calculateTextSimilarity(dishName: dishName, detectedText: detectedText)
            
            // Only consider matches above a minimum threshold
            if score > 0.6 && score > bestScore {
                bestScore = score
                bestMatch = region
                print("🎯 Better match for '\(dishName)': '\(detectedText)' (score: \(score))")
            }
        }
        
        return bestMatch
    }
    
    // Calculate text similarity using multiple strategies
    private func calculateTextSimilarity(dishName: String, detectedText: String) -> Double {
        let dishWords = dishName.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let detectedWords = detectedText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        // Strategy 1: Exact match
        if dishName == detectedText {
            return 1.0
        }
        
        // Strategy 2: Substring match
        if detectedText.contains(dishName) || dishName.contains(detectedText) {
            return 0.9
        }
        
        // Strategy 3: Word matching
        var matchedWords = 0
        for dishWord in dishWords {
            if dishWord.count >= 3 { // Only consider meaningful words
                for detectedWord in detectedWords {
                    if detectedWord.contains(dishWord) || dishWord.contains(detectedWord) {
                        matchedWords += 1
                        break
                    }
                }
            }
        }
        
        if dishWords.count > 0 {
            let wordMatchScore = Double(matchedWords) / Double(dishWords.count)
            if wordMatchScore > 0.5 {
                return 0.7 + (wordMatchScore * 0.2) // 0.7 to 0.9 range
            }
        }
        
        // Strategy 4: Fuzzy matching (simplified Levenshtein-like approach)
        let commonCharacters = Set(dishName).intersection(Set(detectedText)).count
        let totalCharacters = Set(dishName).union(Set(detectedText)).count
        let characterSimilarity = totalCharacters > 0 ? Double(commonCharacters) / Double(totalCharacters) : 0.0
        
        if characterSimilarity > 0.6 {
            return characterSimilarity * 0.6 // 0.36 to 0.6 range
        }
        
        return 0.0
    }
    
    // MARK: - Image Annotation
    private func createAnnotatedImage(
        baseImage: UIImage,
        matchedDishes: [(dish: DishAnalysis, textRegion: DetectedTextRegion)]
    ) -> UIImage {
        print("📊 MenuAnnotationManager: Creating annotated image")
        print("   Input base image size: \(baseImage.size)")
        print("   Input base image scale: \(baseImage.scale)")
        print("   Input base image orientation: \(baseImage.imageOrientation.rawValue)")
        
        guard let cgImage = baseImage.cgImage else {
            print("❌ Failed to get CGImage from base image")
            return baseImage
        }
        
        // STEP 1: Determine how the image will be displayed in SwiftUI
        // SwiftUI constrains to screen bounds with aspect ratio preservation
        let maxDisplayWidth = UIScreen.main.bounds.width * 1.5
        let maxDisplayHeight = UIScreen.main.bounds.height * 1.5
        
        let originalSize = baseImage.size
        let aspectRatio = originalSize.width / originalSize.height
        
        // Calculate the actual display size (how SwiftUI will size the image)
        var displaySize: CGSize
        if originalSize.width > maxDisplayWidth || originalSize.height > maxDisplayHeight {
            // Image needs to be scaled down to fit
            if aspectRatio > (maxDisplayWidth / maxDisplayHeight) {
                // Width is the limiting factor
                displaySize = CGSize(width: maxDisplayWidth, height: maxDisplayWidth / aspectRatio)
            } else {
                // Height is the limiting factor
                displaySize = CGSize(width: maxDisplayHeight * aspectRatio, height: maxDisplayHeight)
            }
        } else {
            // Image fits within bounds, use original size
            displaySize = originalSize
        }
        
        print("   Original size: \(originalSize)")
        print("   Display size: \(displaySize)")
        print("   Max display bounds: \(maxDisplayWidth) x \(maxDisplayHeight)")
        
        // STEP 2: Calculate scaling factor from original to display coordinates
        let scaleX = displaySize.width / originalSize.width
        let scaleY = displaySize.height / originalSize.height
        
        print("   Coordinate scaling: x=\(scaleX), y=\(scaleY)")
        
        // STEP 3: Create the annotated image at display size
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0  // Use 1.0 scale for display rendering
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: displaySize, format: format)
        
        let annotatedImage = renderer.image { context in
            let cgContext = context.cgContext
            
            // Save the current graphics state
            cgContext.saveGState()
            
            // Draw the base image scaled to display size
            baseImage.draw(in: CGRect(origin: .zero, size: displaySize))
            
            // STEP 3.5: Draw explanatory header "Restaurant Dish Margins" at the top
            drawHeaderText(on: context, imageSize: displaySize)
            
            // STEP 4: Draw annotations with coordinates scaled to display size
            for (dish, textRegion) in matchedDishes {
                // Scale the original image coordinates to display coordinates
                let scaledBounds = CGRect(
                    x: textRegion.boundingBox.origin.x * scaleX,
                    y: textRegion.boundingBox.origin.y * scaleY,
                    width: textRegion.boundingBox.size.width * scaleX,
                    height: textRegion.boundingBox.size.height * scaleY
                )
                
                let scaledRegion = DetectedTextRegion(
                    text: textRegion.text,
                    boundingBox: scaledBounds,
                    confidence: textRegion.confidence
                )
                
                print("📍 Drawing annotation for '\(dish.dishName)'")
                print("   Original bounds: \(textRegion.boundingBox)")
                print("   Display bounds: \(scaledBounds)")
                
                drawVisionBasedAnnotation(
                    for: dish,
                    at: scaledRegion,
                    on: context,
                    imageSize: displaySize
                )
            }
            
            // Restore the graphics state
            cgContext.restoreGState()
        }
        
        print("📊 MenuAnnotationManager: Finished creating annotated image")
        print("   Output image size: \(annotatedImage.size)")
        print("   Output image scale: \(annotatedImage.scale)")
        
        return annotatedImage
    }
    
    // Draw annotation based on Vision-detected text location
    private func drawVisionBasedAnnotation(
        for dish: DishAnalysis,
        at textRegion: DetectedTextRegion,
        on context: UIGraphicsImageRendererContext,
        imageSize: CGSize
    ) {
        let cgContext = context.cgContext
        
        // Get the detected text bounding box
        let textRect = textRegion.boundingBox
        
        // HIDDEN: Draw a colored bounding box around the detected dish title (keeping code but not drawing)
        let borderColor = getMarginColor(for: dish.marginPercentage)
        let textColor = getTextColor(for: dish.marginPercentage)
        // cgContext.setStrokeColor(borderColor.cgColor) // HIDDEN
        // cgContext.setLineWidth(3.0) // HIDDEN
        
        // HIDDEN: Add some padding around the text (keeping logic for positioning)
        let paddedRect = textRect.insetBy(dx: -2, dy: -2)
        // cgContext.stroke(paddedRect) // HIDDEN - not drawing bounding box
        
        // Create much bigger percentage badge to the right of bounding box
        let marginText = "\(dish.marginPercentage)%"
        let categoryText = getMarginCategoryLabel(for: dish.marginPercentage) // Updated to use new labels
        
        // Much larger font for the percentage badge
        let percentageFont = UIFont.boldSystemFont(ofSize: 24) // Much bigger
        let categoryFont = UIFont.systemFont(ofSize: 12)
        
        let percentageAttributes: [NSAttributedString.Key: Any] = [
            .font: percentageFont,
            .foregroundColor: textColor
        ]
        
        let categoryAttributes: [NSAttributedString.Key: Any] = [
            .font: categoryFont,
            .foregroundColor: textColor
        ]
        
        // Calculate badge size
        let percentageSize = marginText.size(withAttributes: percentageAttributes)
        let categorySize = categoryText.size(withAttributes: categoryAttributes)
        
        let badgeWidth = max(percentageSize.width, categorySize.width) + 16
        let badgeHeight = percentageSize.height + categorySize.height + 12
        
        // Position badge to the right of the bounding box with some spacing
        let badgeX = textRect.maxX + 10
        let badgeY = textRect.midY - (badgeHeight / 2)
        
        let badgeRect = CGRect(
            x: badgeX,
            y: badgeY,
            width: badgeWidth,
            height: badgeHeight
        )
        
        // Draw badge background with rounded corners
        cgContext.setFillColor(borderColor.cgColor)
        let roundedBadge = UIBezierPath(roundedRect: badgeRect, cornerRadius: 8)
        cgContext.addPath(roundedBadge.cgPath)
        cgContext.fillPath()
        
        // Draw white border around badge
        cgContext.setStrokeColor(UIColor.white.cgColor)
        cgContext.setLineWidth(2.0)
        cgContext.addPath(roundedBadge.cgPath)
        cgContext.strokePath()
        
        // Draw percentage text (centered in badge)
        let percentageRect = CGRect(
            x: badgeRect.minX + 8,
            y: badgeRect.minY + 6,
            width: badgeRect.width - 16,
            height: percentageSize.height
        )
        
        // Draw category text below percentage
        let categoryRect = CGRect(
            x: badgeRect.minX + 8,
            y: percentageRect.maxY + 2,
            width: badgeRect.width - 16,
            height: categorySize.height
        )
        
        // Save graphics state before text drawing
        cgContext.saveGState()
        
        // Set text drawing mode to fill for proper rendering
        cgContext.setTextDrawingMode(.fill)
        
        // Center-align text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        var centeredPercentageAttributes = percentageAttributes
        centeredPercentageAttributes[.paragraphStyle] = paragraphStyle
        
        var centeredCategoryAttributes = categoryAttributes
        centeredCategoryAttributes[.paragraphStyle] = paragraphStyle
        
        marginText.draw(in: percentageRect, withAttributes: centeredPercentageAttributes)
        categoryText.draw(in: categoryRect, withAttributes: centeredCategoryAttributes)
        
        // Restore graphics state
        cgContext.restoreGState()
        
        // STEP 5: Draw justification text underneath the dish title area
        drawJustificationText(
            for: dish,
            below: textRect,
            on: context,
            imageSize: imageSize
        )
        
        print("📊 Drew annotation for '\(dish.dishName)' (\(dish.marginPercentage)% - \(categoryText)) with badge and justification")
        print("   Detected text: '\(textRegion.text)' at bounds: \(textRect)")
        print("   Badge positioned at: \(badgeRect)")
        print("   Image size: \(imageSize)")
    }
    
    // MARK: - Color Coding Functions
    
    // Get margin color based on percentage ranges
    private func getMarginColor(for percentage: Int) -> UIColor {
        switch percentage {
        case 75...:
            return UIColor.systemRed // High margins are bad
        case 65...74:
            return UIColor.systemOrange // Medium margins
        default: // <65%
            return UIColor.systemGreen // Low margins are good
        }
    }
    
    // Get text color for proper contrast based on percentage
    private func getTextColor(for percentage: Int) -> UIColor {
        switch percentage {
        case 75...:
            return UIColor.white // Red background
        case 65...74:
            return UIColor.white // Orange background
        default: // <65%
            return UIColor.white // Green background
        }
    }
    
    // Helper function to convert UIImage orientation to CGImagePropertyOrientation
    private func cgImagePropertyOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up:
            return .up
        case .down:
            return .down
        case .left:
            return .left
        case .right:
            return .right
        case .upMirrored:
            return .upMirrored
        case .downMirrored:
            return .downMirrored
        case .leftMirrored:
            return .leftMirrored
        case .rightMirrored:
            return .rightMirrored
        @unknown default:
            return .up
        }
    }
    
    // Get margin category description (kept for backward compatibility)
    private func getMarginCategory(for percentage: Int) -> String {
        switch percentage {
        case 75...:
            return "Very High"  // Red - bad margins
        case 65...74:
            return "High"       // Orange - medium margins  
        default: // <65%
            return "Good"       // Green - good margins
        }
    }
    
    // Get margin category label for annotations (updated labels)
    private func getMarginCategoryLabel(for percentage: Int) -> String {
        switch percentage {
        case 75...:
            return "High Margin Item"  // Red - bad margins
        case 65...74:
            return "Med. Margin Item"  // Orange - medium margins  
        default: // <65%
            return "Low Margin Item"   // Green - good margins
        }
    }
    
    // MARK: - Helper Functions
    
    // Helper function to wrap text
    private func wrapText(_ text: String, maxWidth: CGFloat) -> String {
        let words = text.split(separator: " ")
        var lines: [String] = []
        var currentLine = ""
        
        for word in words {
            let testLine = currentLine.isEmpty ? String(word) : currentLine + " " + String(word)
            if testLine.count > 40 { // Approximate character limit per line
                if !currentLine.isEmpty {
                    lines.append(currentLine)
                    currentLine = String(word)
                } else {
                    lines.append(String(word))
                }
            } else {
                currentLine = testLine
            }
        }
        
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        
        return lines.joined(separator: "\n")
    }
    
    // Helper function to calculate multi-line text size
    private func calculateTextSize(text: String, attributes: [NSAttributedString.Key: Any], maxWidth: CGFloat) -> CGSize {
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let rect = attributedString.boundingRect(
            with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return rect.size
    }
    
    // Helper function to draw wrapped text
    private func drawWrappedText(text: String, in rect: CGRect, attributes: [NSAttributedString.Key: Any]) {
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(in: rect)
    }
    
    // MARK: - Header and Justification Text Drawing
    
    /// Draw explanatory header text at the top of the image
    private func drawHeaderText(on context: UIGraphicsImageRendererContext, imageSize: CGSize) {
        let cgContext = context.cgContext
        
        // Header text setup
        let headerText = "Restaurant Dish Margins"
        let headerFont = UIFont.boldSystemFont(ofSize: 28)
        let headerColor = UIColor.black
        
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: headerColor
        ]
        
        let headerSize = headerText.size(withAttributes: headerAttributes)
        
        // Position header at top center with some margin
        let headerRect = CGRect(
            x: (imageSize.width - headerSize.width) / 2,
            y: 20, // Top margin
            width: headerSize.width,
            height: headerSize.height
        )
        
        // Draw white background for header text
        cgContext.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
        let headerBackground = CGRect(
            x: headerRect.minX - 10,
            y: headerRect.minY - 5,
            width: headerRect.width + 20,
            height: headerRect.height + 10
        )
        let roundedHeaderBg = UIBezierPath(roundedRect: headerBackground, cornerRadius: 8)
        cgContext.addPath(roundedHeaderBg.cgPath)
        cgContext.fillPath()
        
        // Draw header text
        cgContext.saveGState()
        cgContext.setTextDrawingMode(.fill)
        headerText.draw(in: headerRect, withAttributes: headerAttributes)
        cgContext.restoreGState()
        
        print("📊 Drew header text: '\(headerText)' at position: \(headerRect)")
    }
    
    /// Draw justification text underneath the dish title area
    private func drawJustificationText(
        for dish: DishAnalysis,
        below textRect: CGRect,
        on context: UIGraphicsImageRendererContext,
        imageSize: CGSize
    ) {
        let cgContext = context.cgContext
        
        // Justification text setup - small but readable
        let justificationFont = UIFont.systemFont(ofSize: 11)
        let justificationColor = UIColor.black
        
        let justificationAttributes: [NSAttributedString.Key: Any] = [
            .font: justificationFont,
            .foregroundColor: justificationColor
        ]
        
        // Wrap the justification text to fit within a reasonable width
        let maxWidth: CGFloat = min(300, imageSize.width * 0.6) // Max 60% of image width or 300pts
        let wrappedJustification = wrapText(dish.justification, maxWidth: maxWidth)
        
        let justificationSize = calculateTextSize(
            text: wrappedJustification,
            attributes: justificationAttributes,
            maxWidth: maxWidth
        )
        
        // Position justification text below the dish title area
        let justificationRect = CGRect(
            x: textRect.minX, // Align with left edge of dish title
            y: textRect.maxY + 5, // Small gap below the dish title
            width: min(justificationSize.width, maxWidth),
            height: justificationSize.height
        )
        
        // Ensure justification doesn't go off the image
        let adjustedRect = CGRect(
            x: min(justificationRect.minX, imageSize.width - justificationRect.width - 10),
            y: min(justificationRect.minY, imageSize.height - justificationRect.height - 10),
            width: justificationRect.width,
            height: justificationRect.height
        )
        
        // Draw semi-transparent white background for justification text
        cgContext.setFillColor(UIColor.white.withAlphaComponent(0.85).cgColor)
        let justificationBackground = CGRect(
            x: adjustedRect.minX - 4,
            y: adjustedRect.minY - 3,
            width: adjustedRect.width + 8,
            height: adjustedRect.height + 6
        )
        let roundedJustificationBg = UIBezierPath(roundedRect: justificationBackground, cornerRadius: 6)
        cgContext.addPath(roundedJustificationBg.cgPath)
        cgContext.fillPath()
        
        // Draw justification text
        cgContext.saveGState()
        cgContext.setTextDrawingMode(.fill)
        drawWrappedText(
            text: wrappedJustification,
            in: adjustedRect,
            attributes: justificationAttributes
        )
        cgContext.restoreGState()
        
        print("📊 Drew justification for '\(dish.dishName)': '\(wrappedJustification.prefix(50))...'") 
        print("   Justification positioned at: \(adjustedRect)")
    }
    
    // Reset annotation state
    func resetAnnotation() {
        annotatedImageData = nil
        error = nil
        print("📊 MenuAnnotationManager: Reset annotation state")
    }
}
