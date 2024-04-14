//
//  ViewController.swift
//  ImageLoadingApp
//
//  Created by Harshit on 14/04/24.
//

import UIKit

class ImageGridViewController: UIViewController {
    
    // IBOutlet to connect with the UICollectionView in Interface Builder
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Array to store URLs of images
    private var imageUrls: [String] = []
    
    // Cache to store images
    private let imageCache = NSCache<NSString, UIImage>()
    
    // viewDidLoad method
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set delegate and datasource of UICollectionView
        collectionView.delegate = self
        collectionView.dataSource = self
        
        
        // Fetch images from Unsplash API
        fetchImages()
    }
    
    // Method to fetch images from Unsplash API
    func fetchImages() {
        // API endpoint URL for fetching random images
        let urlString = "https://api.unsplash.com/photos/random?count=30&client_id=<YOUR_ACCESS_KEY>"
        
        // Create URL object from urlString
        guard let url = URL(string: urlString) else {
            // Print error message if URL is invalid
            print("Invalid URL")
            return
        }
        
        // Create URLSession data task to fetch data from the URL
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                // Print error message if request fails
                print("Error fetching images: \(error.localizedDescription)")
                // Handle error if needed
                return
            }
            
            guard let data = data else {
                // Print error message if no data is received
                print("No data received")
                return
            }
            
            do {
                // Parse JSON data to extract image URLs
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
                self.imageUrls = json?.compactMap { $0["urls"] as? [String: Any] } .map { $0["regular"] as? String ?? "" } ?? []
                
                // Reload collection view on the main thread
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            } catch {
                // Print error message if JSON parsing fails
                print("Error parsing JSON: \(error.localizedDescription)")
            }
        }.resume() // Resume the data task
    }
    
    // Method to load image with caching
    func loadImageWithCache(from url: URL, placeholder: UIImage?, completion: @escaping (UIImage?) -> Void) {
        // Show placeholder image
        completion(placeholder)
        
        // Check if image is cached
        if let cachedImage = imageCache.object(forKey: url.absoluteString as NSString) {
            // Return cached image if available
            completion(cachedImage)
        } else {
            // Show loader (activity indicator)
            DispatchQueue.main.async {
                // Start activity indicator
                // Show loading UI (e.g., spinner)
            }
            
            // Otherwise, fetch image from URL
            URLSession.shared.dataTask(with: url) { data, response, error in
                // Hide loader (activity indicator)
                DispatchQueue.main.async {
                    // Stop activity indicator
                    // Hide loading UI
                }
                
                guard let data = data, error == nil else {
                    // Call completion handler with nil if error occurs
                    completion(nil)
                    return
                }
                if let image = UIImage(data: data) {
                    // Cache image and call completion handler with image
                    self.imageCache.setObject(image, forKey: url.absoluteString as NSString)
                    completion(image)
                } else {
                    // Call completion handler with nil if image data is invalid
                    completion(nil)
                }
            }.resume() // Resume the data task
        }
    }
}

// Extension to conform to UICollectionViewDataSource protocol
extension ImageGridViewController: UICollectionViewDataSource {
    // Method to return number of items in collection view
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }
    
    // Method to configure and return cell for item at index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Dequeue reusable cell with identifier "ImageCell"
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCell else {
            // Return empty cell if casting fails
            return UICollectionViewCell()
        }
        
        // Get image URL for current item
        let imageUrlString = imageUrls[indexPath.item]
        guard let imageUrl = URL(string: imageUrlString) else {
            // Handle invalid URL
            return cell
        }
        
        // Load image with caching and show placeholder
        loadImageWithCache(from: imageUrl, placeholder:UIImage(systemName: "photo.artframe")) { image in
            DispatchQueue.main.async {
                if let image = image {
                    // Set image to image view if image is available
                    cell.imageView.image = image
                } else {
                    // Handle error or set placeholder image
                    cell.imageView.image = UIImage(named: "NOImage") // Set error image or handle appropriately
                }
            }
        }
        // Return configured cell
        return cell
    }
}

// Extension to conform to UICollectionViewDelegateFlowLayout protocol
extension ImageGridViewController: UICollectionViewDelegateFlowLayout {
    // Method to return size for item at index path
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Calculate item size based on collection view width
        let frame = self.collectionView.frame.size.width / 3.17
        return CGSize(width: frame, height: frame)
    }
}

// ImageCell class definition
class ImageCell: UICollectionViewCell {
    // IBOutlet to connect with the UIImageView in Interface Builder
    @IBOutlet weak var imageView: UIImageView!
    
    // Method called before cell is reused
    override func prepareForReuse() {
        super.prepareForReuse()
        // Clear image view to avoid displaying incorrect images while scrolling
        imageView.image = nil
    }
}
