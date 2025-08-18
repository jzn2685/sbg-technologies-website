//
//  GeminiVehicleRecognitionService.swift
//  CrashiQ
//
//  Created on 2025-07-18.
//  Service for integrating Google Gemini AI for enhanced vehicle recognition,
//  especially for damaged vehicles.
//

import Foundation
import GoogleGenerativeAI
import UIKit
import os.log

// MARK: - Service Configuration

struct GeminiServiceConfiguration {
    static let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""
    static let modelName = "gemini-pro-vision"
    static let cacheExpirationHours: TimeInterval = 24
    static let maxRetries = 3
    static let timeoutInterval: TimeInterval = 30
}

// MARK: - Cache Entry Model

struct GeminiCacheEntry: Codable {
    let imageHash: String
    let result: VehicleRecognitionResult
    let timestamp: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > (GeminiServiceConfiguration.cacheExpirationHours * 3600)
    }
}

// MARK: - Service Error Types

enum GeminiServiceError: LocalizedError {
    case invalidAPIKey
    case modelNotAvailable
    case imageProcessingFailed
    case networkError(Error)
    case invalidResponse
    case quotaExceeded
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid Gemini API key"
        case .modelNotAvailable:
            return "Gemini model is not available"
        case .imageProcessingFailed:
            return "Failed to process image"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from Gemini API"
        case .quotaExceeded:
            return "API quota exceeded"
        case .timeout:
            return "Request timeout"
        }
    }
}

// MARK: - Main Service Class

@available(iOS 15.0, *)
final class GeminiVehicleRecognitionService {
    
    // MARK: - Properties
    
    private let generativeModel: GenerativeModel?
    private let domesticVehicleDatabase: DomesticVehicleImageDatabase
    private let cache = NSCache<NSString, GeminiCacheEntry>()
    private let persistentCacheURL: URL
    private let logger = Logger(subsystem: "com.crashiq.app", category: "GeminiService")
    private let operationQueue = DispatchQueue(label: "com.crashiq.gemini.service", qos: .userInitiated)
    
    // MARK: - Singleton
    
    static let shared = GeminiVehicleRecognitionService()
    
    // MARK: - Initialization
    
    private init() {
        // Initialize domestic vehicle database
        self.domesticVehicleDatabase = DomesticVehicleImageDatabase.shared
        
        // Setup persistent cache directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.persistentCacheURL = documentsPath.appendingPathComponent("GeminiCache")
        
        // Create cache directory if needed
        try? FileManager.default.createDirectory(at: persistentCacheURL, withIntermediateDirectories: true)
        
        // Initialize Gemini model
        if !GeminiServiceConfiguration.apiKey.isEmpty {
            self.generativeModel = GenerativeModel(
                name: GeminiServiceConfiguration.modelName,
                apiKey: GeminiServiceConfiguration.apiKey
            )
            logger.info("Gemini service initialized successfully")
        } else {
            self.generativeModel = nil
            logger.warning("Gemini service initialized without API key - will use fallback recognition")
        }
        
        // Load persistent cache
        loadPersistentCache()
    }
    
    // MARK: - Public Methods
    
    /// Recognizes vehicle from image using Gemini AI with fallback to local recognition
    /// - Parameter image: The vehicle image to analyze
    /// - Returns: Vehicle recognition result
    public func recognizeVehicle(from image: UIImage) async throws -> VehicleRecognitionResult {
        logger.info("Starting vehicle recognition")
        
        // Check cache first
        let imageHash = computeImageHash(image)
        if let cachedResult = getCachedResult(for: imageHash) {
            logger.info("Returning cached result for image")
            return cachedResult
        }
        
        // Try Gemini recognition first if available
        if generativeModel != nil {
            do {
                let geminiResult = try await recognizeWithGemini(image: image)
                
                // Cache the result
                cacheResult(geminiResult, for: imageHash)
                
                logger.info("Successfully recognized vehicle with Gemini: \(geminiResult.vehicleModel ?? "Unknown")")
                return geminiResult
            } catch {
                logger.error("Gemini recognition failed: \(error.localizedDescription)")
                // Fall through to use local recognition
            }
        }
        
        // Fallback to local recognition
        logger.info("Using fallback local recognition")
        return try await recognizeWithLocalDatabase(image: image)
    }
    
    /// Preloads Gemini model for faster first recognition
    public func preloadModel() async {
        guard generativeModel != nil else {
            logger.warning("Cannot preload - Gemini model not initialized")
            return
        }
        
        logger.info("Preloading Gemini model")
        // Model preloading logic would go here if supported by the SDK
    }
    
    /// Clears all cached results
    public func clearCache() {
        cache.removeAllObjects()
        
        // Clear persistent cache
        if let files = try? FileManager.default.contentsOfDirectory(at: persistentCacheURL, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }
        
        logger.info("Cache cleared")
    }
    
    // MARK: - Private Methods - Gemini Recognition
    
    private func recognizeWithGemini(image: UIImage) async throws -> VehicleRecognitionResult {
        guard let model = generativeModel else {
            throw GeminiServiceError.modelNotAvailable
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GeminiServiceError.imageProcessingFailed
        }
        
        // Create prompt for vehicle recognition
        let prompt = """
        Analyze this vehicle image and provide the following information:
        1. Vehicle make (manufacturer)
        2. Vehicle model
        3. Approximate year or year range
        4. Vehicle type (sedan, SUV, truck, etc.)
        5. Damage assessment if visible (minor, moderate, severe)
        6. Confidence level (0-100%)
        
        Focus on identifying the vehicle even if it's damaged. Provide your response in the following JSON format:
        {
            "make": "manufacturer name",
            "model": "model name",
            "year": "year or year range",
            "type": "vehicle type",
            "damage": "damage level or none",
            "confidence": confidence_percentage
        }
        """
        
        let imagePart = ModelContent.Part.data(mimetype: "image/jpeg", imageData)
        let textPart = ModelContent.Part.text(prompt)
        
        do {
            let response = try await model.generateContent([textPart, imagePart])
            
            guard let text = response.text else {
                throw GeminiServiceError.invalidResponse
            }
            
            return try parseGeminiResponse(text)
        } catch {
            if error.localizedDescription.contains("quota") {
                throw GeminiServiceError.quotaExceeded
            } else {
                throw GeminiServiceError.networkError(error)
            }
        }
    }
    
    private func parseGeminiResponse(_ responseText: String) throws -> VehicleRecognitionResult {
        // Extract JSON from response
        guard let jsonData = extractJSON(from: responseText)?.data(using: .utf8) else {
            throw GeminiServiceError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            let geminiResponse = try decoder.decode(GeminiVehicleResponse.self, from: jsonData)
            
            return VehicleRecognitionResult(
                vehicleMake: geminiResponse.make,
                vehicleModel: geminiResponse.model,
                vehicleYear: geminiResponse.year,
                vehicleType: geminiResponse.type,
                confidence: Float(geminiResponse.confidence) / 100.0,
                recognitionSource: .geminiAI,
                damageAssessment: parseDamageLevel(geminiResponse.damage),
                additionalInfo: [
                    "gemini_raw_response": responseText,
                    "damage_description": geminiResponse.damage ?? "none"
                ]
            )
        } catch {
            throw GeminiServiceError.invalidResponse
        }
    }
    
    private func extractJSON(from text: String) -> String? {
        // Find JSON content between curly braces
        if let startRange = text.range(of: "{"),
           let endRange = text.range(of: "}", options: .backwards) {
            return String(text[startRange.lowerBound...endRange.upperBound])
        }
        return nil
    }
    
    private func parseDamageLevel(_ damage: String?) -> DamageLevel {
        switch damage?.lowercased() {
        case "minor":
            return .minor
        case "moderate":
            return .moderate
        case "severe":
            return .severe
        default:
            return .none
        }
    }
    
    // MARK: - Private Methods - Local Recognition
    
    private func recognizeWithLocalDatabase(image: UIImage) async throws -> VehicleRecognitionResult {
        // This would integrate with the existing DomesticVehicleImageDatabase
        // For now, returning a placeholder implementation
        return await domesticVehicleDatabase.recognize(image: image)
    }
    
    // MARK: - Private Methods - Caching
    
    private func computeImageHash(_ image: UIImage) -> String {
        guard let data = image.jpegData(compressionQuality: 0.5) else {
            return UUID().uuidString
        }
        
        return data.base64EncodedString().hash.description
    }
    
    private func getCachedResult(for imageHash: String) -> VehicleRecognitionResult? {
        // Check memory cache
        if let entry = cache.object(forKey: imageHash as NSString) {
            if !entry.isExpired {
                return entry.result
            } else {
                cache.removeObject(forKey: imageHash as NSString)
            }
        }
        
        // Check persistent cache
        let cacheFile = persistentCacheURL.appendingPathComponent("\(imageHash).json")
        if let data = try? Data(contentsOf: cacheFile),
           let entry = try? JSONDecoder().decode(GeminiCacheEntry.self, from: data),
           !entry.isExpired {
            // Add to memory cache
            cache.setObject(entry, forKey: imageHash as NSString)
            return entry.result
        }
        
        return nil
    }
    
    private func cacheResult(_ result: VehicleRecognitionResult, for imageHash: String) {
        let entry = GeminiCacheEntry(
            imageHash: imageHash,
            result: result,
            timestamp: Date()
        )
        
        // Memory cache
        cache.setObject(entry, forKey: imageHash as NSString)
        
        // Persistent cache
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            let cacheFile = self.persistentCacheURL.appendingPathComponent("\(imageHash).json")
            if let data = try? JSONEncoder().encode(entry) {
                try? data.write(to: cacheFile)
            }
        }
    }
    
    private func loadPersistentCache() {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let files = try FileManager.default.contentsOfDirectory(
                    at: self.persistentCacheURL,
                    includingPropertiesForKeys: nil
                )
                
                for file in files {
                    if file.pathExtension == "json",
                       let data = try? Data(contentsOf: file),
                       let entry = try? JSONDecoder().decode(GeminiCacheEntry.self, from: data),
                       !entry.isExpired {
                        self.cache.setObject(entry, forKey: entry.imageHash as NSString)
                    }
                }
                
                self.logger.info("Loaded \(self.cache.name) entries from persistent cache")
            } catch {
                self.logger.error("Failed to load persistent cache: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Supporting Models

struct GeminiVehicleResponse: Codable {
    let make: String
    let model: String
    let year: String
    let type: String
    let damage: String?
    let confidence: Int
}

// MARK: - Placeholder Models (These should match your existing models)

enum RecognitionSource {
    case geminiAI
    case localDatabase
    case manual
}

enum DamageLevel {
    case none
    case minor
    case moderate
    case severe
}

struct VehicleRecognitionResult: Codable {
    let vehicleMake: String
    let vehicleModel: String
    let vehicleYear: String
    let vehicleType: String
    let confidence: Float
    let recognitionSource: RecognitionSource
    let damageAssessment: DamageLevel
    let additionalInfo: [String: String]
}

// MARK: - Placeholder for existing database (should be replaced with actual implementation)

class DomesticVehicleImageDatabase {
    static let shared = DomesticVehicleImageDatabase()
    
    func recognize(image: UIImage) async -> VehicleRecognitionResult {
        // Placeholder implementation
        return VehicleRecognitionResult(
            vehicleMake: "Unknown",
            vehicleModel: "Unknown",
            vehicleYear: "Unknown",
            vehicleType: "Unknown",
            confidence: 0.0,
            recognitionSource: .localDatabase,
            damageAssessment: .none,
            additionalInfo: [:]
        )
    }
}

// MARK: - Usage Example

/*
// Example usage in your view controller or view model:

class VehicleRecognitionViewController: UIViewController {
    
    func recognizeVehicle(from image: UIImage) {
        Task {
            do {
                let result = try await GeminiVehicleRecognitionService.shared.recognizeVehicle(from: image)
                
                // Update UI with result
                DispatchQueue.main.async {
                    self.updateUI(with: result)
                }
            } catch {
                // Handle error
                print("Recognition failed: \(error)")
            }
        }
    }
    
    func updateUI(with result: VehicleRecognitionResult) {
        // Update your UI with the recognition result
        print("Vehicle: \(result.vehicleMake) \(result.vehicleModel) (\(result.vehicleYear))")
        print("Confidence: \(result.confidence * 100)%")
        print("Damage: \(result.damageAssessment)")
    }
}
*/