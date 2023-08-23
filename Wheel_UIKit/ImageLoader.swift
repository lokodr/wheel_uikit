//
//  ImageLoader.swift
//  wheel_uikit
//
//  Created by Lynn on 2023-08-16.
//

import Foundation
import UIKit
import Photos
import OSLog


// MARK: - ImageLoaderDelegate Protocol

protocol ImageLoaderDelegate: AnyObject {
    
    func imageLoader(_ loader: ImageLoader, didLoadImages images: [UIImage])
    func imageLoader(_ loader: ImageLoader, didFailWithError error: Error)
}

// MARK: - ImageLoader Protocol

protocol ImageLoader {
    
    var delegate: ImageLoaderDelegate? { get set }
    func loadImages(numberOfImages: Int)
}


// MARK: - LocalImageLoader

class LocalImageLoader: ImageLoader {
    
    weak var delegate: ImageLoaderDelegate?
    
    func loadImages(numberOfImages: Int) {
        
        DispatchQueue.global().async { [weak self] in
            
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                
                guard let self = self else { return }
                
                switch status {
                    
                case .authorized:
                    let assets = PHAsset.fetchAssets(with: .image, options: nil)
                    var randomIndexes: Set<Int> = []
                    while randomIndexes.count < numberOfImages {
                        randomIndexes.insert(Int.random(in: 0..<assets.count))
                    }
                    
                    var photosQueue: [UIImage] = []
                    
                    for index in randomIndexes {
                        let asset = assets.object(at: index)
                        let options = PHImageRequestOptions()
                        options.isSynchronous = true
                        PHImageManager.default().requestImage(for: asset,
                                                              targetSize: CGSize(width: asset.pixelWidth,
                                                                                 height: asset.pixelHeight),
                                                              contentMode: .aspectFit,
                                                              options: options) { (image, _) in
                            if let image = image {
                                photosQueue.append(image)
                            }
                            if photosQueue.count == numberOfImages {
                                self.delegate?.imageLoader(self, didLoadImages: photosQueue)
                            }
                        }
                    }
                case .denied, .restricted, .notDetermined:
                    let error = NSError(domain: "LocalImageLoader", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permission denied"])
                    self.delegate?.imageLoader(self, didFailWithError: error)
                case .limited:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
}


// MARK: - APIImageLoader

class APIImageLoader: ImageLoader {
    
    weak var delegate: ImageLoaderDelegate?
    private let apiKey = "38896046-090311b64efef5f4ff14a2576"
    let keywords = ["waterfall", "trees", "music", "stars"]
    
    func loadImages(numberOfImages: Int) {
        
        os_signpost(.begin, log: Logger.poiLog, name: Logger.loadImageAPIActivities)
        
        let keyword = keywords.randomElement()!
        let apiUrl = "https://pixabay.com/api/?key=\(apiKey)&q=\(keyword)&per_page=\(numberOfImages)"
        
        guard let url = URL(string: apiUrl) else {
            
            let error = NSError()
            delegate?.imageLoader(self, didFailWithError: error)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            
            guard let self = self else {
                
                return
            }
            
            if let error = error {
                
                self.delegate?.imageLoader(self, didFailWithError: error)
                return
            }
            
            if let data = data {
                
                do {
                    
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(APIResponse.self, from: data)
                    self.fetchImages(from: response.hits)
                } catch {
                    
                    self.delegate?.imageLoader(self, didFailWithError: error)
                }
            }
        }.resume()
    }
    
    private func fetchImages(from results: [APIImage]) {
        
        var images: [UIImage] = []
        let group = DispatchGroup()
        
        // Create multiple async image-downloading tasks
        for result in results {
            
            group.enter()
            
            if let imageUrl = URL(string: result.largeImageURL) {
                
                DispatchQueue.global().async {
                    
                    if let imageData = try? Data(contentsOf: imageUrl),
                       let image = UIImage(data: imageData) {
                        images.append(image)
                    }
                    group.leave()
                }
            } else {
                group.leave()
            }
        }
        
        //When all tasks have finished, notify delegate
        group.notify(queue: .main) { [weak self] in
            os_signpost(.end, log: Logger.poiLog, name: Logger.loadImageAPIActivities)
            self?.delegate?.imageLoader(self!, didLoadImages: images)
        }
    }
}


// MARK: - APIResponse and APIImage Structs

struct APIResponse: Codable {
    
    let hits: [APIImage]
}

struct APIImage: Codable {
    
    let largeImageURL: String
}


// MARK: - MockImageLoader

class MockImageLoader: ImageLoader {
    
    weak var delegate: ImageLoaderDelegate?
    
    func loadImages(numberOfImages: Int) {
        
        var images: [UIImage] = []
        let imageSize = CGSize(width: 200, height: 200)

        for _ in 0..<numberOfImages {
            images.append(generateRandomColorImage(size: imageSize))
        }
                
        delegate?.imageLoader(self, didLoadImages: images)
    }
    
    func generateRandomColorImage(size: CGSize) -> UIImage {
        
        let red = CGFloat(arc4random_uniform(256)) / 255.0
        let green = CGFloat(arc4random_uniform(256)) / 255.0
        let blue = CGFloat(arc4random_uniform(256)) / 255.0
        let color = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(CGRect(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image ?? UIImage()
    }
}
