//
//  ViewController.swift
//  wheel_uikit
//
//  Created by Lynn on 2023-08-16.
//

import UIKit
import Photos
import OSLog

class ViewController: UIViewController {
    
    let wheel = WheelView()
    let numberOfImages = 20
    let imageSize = CGSize(width: 200, height: 200)
    var imagesQueue: [UIImage] = []
    var collectionView: UICollectionView!
    var loadImagesButton: UIButton!
    var imageLoader: ImageLoader!
    var backgroundImageView: UIImageView!
    private var transitionWorkItem: DispatchWorkItem?

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        os_signpost(.begin, log: Logger.poiLog, name: Logger.startupActivities)

        setupBackgroundImageView()
        setupImageLoader()
        setupWheel()
        setupCollectionView()
        setupLoadImagesButton()
        
        os_signpost(.end, log: Logger.poiLog, name: Logger.startupActivities)

    }
}


// MARK: - Setup Methods

extension ViewController {
    
    func setupWheel() {
        
        wheel.delegate = self
        let verticalPosition: CGFloat = 260
        wheel.center = CGPoint(x: view.center.x, y: verticalPosition)
        view.addSubview(wheel)
    }
    
    func setupBackgroundImageView() {
        
        backgroundImageView = UIImageView(frame: view.bounds)
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
    }
    
    func setupImageLoader() {
        
        switch AppSettings.imageSource {
        case .Local:
            imageLoader = LocalImageLoader()
        case .API:
            imageLoader = APIImageLoader()
        case .Mock:
            imageLoader = MockImageLoader()
        }
  
        imageLoader.delegate = self
        imageLoader.loadImages(numberOfImages: 20)
    }
    
    private func setupLoadImagesButton() {
        
        let buttonHeight = 48.0
        loadImagesButton = UIButton()
        loadImagesButton.setTitle("Load Images", for: .normal)
        loadImagesButton.setTitleColor(.white, for: .normal)
        loadImagesButton.backgroundColor = Helpers.themeColour
        loadImagesButton.layer.cornerRadius = buttonHeight / 2
        loadImagesButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadImagesButton)
                
        NSLayoutConstraint.activate([
            loadImagesButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadImagesButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -260),
            loadImagesButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            loadImagesButton.heightAnchor.constraint(equalToConstant: buttonHeight)
        ])
        
        loadImagesButton.addTarget(self, action: #selector(loadImagesButtonTapped), for: .touchUpInside)
    }

    
    func setupCollectionView() {

        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 140, height: 140)
        layout.minimumLineSpacing = 10
        layout.scrollDirection = .horizontal
        
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50), // Added a negative constant
            collectionView.heightAnchor.constraint(equalToConstant: 168) // Or whatever height you desire
        ])
    }
}


// MARK: - Button Actions

extension ViewController {
    
    @objc func loadImagesButtonTapped() {

        let randomNumberOfImages = Int.random(in: 10...20)
        imageLoader.loadImages(numberOfImages: randomNumberOfImages)
    }
}


// MARK: - ScrollableDelegate

extension ViewController: ScrollableDelegate {
        
    func didScroll(toPercentage percentage: CGFloat) {
        
        //print(percentage)
        
        if imagesQueue.count == 0 { return }
        let totalItems = imagesQueue.count
        let targetIndex = Int(CGFloat(totalItems - 1) * percentage)
        let indexPath = IndexPath(item: targetIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)

        //set background to the image
        if targetIndex >= 0 && targetIndex < imagesQueue.count {
            let targetImage = imagesQueue[targetIndex]
            setNewBackgroundImage(targetImage)
        }
    }
}


// MARK: - Collection View DataSource & Delegate

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 160, height: 160)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return imagesQueue.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let imageView = UIImageView(image: imagesQueue[indexPath.item])
        cell.contentView.addSubview(imageView)
        imageView.frame = cell.contentView.bounds
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderWidth = 4
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        
        // Label that displays the position of the image
        let label = UILabel(frame: CGRect(x: imageView.bounds.width - 30, y: imageView.bounds.height - 30, width: 20, height: 20)) // Adjust the frame as needed
        label.text = "\(indexPath.item + 1)"
        label.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 10)
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        imageView.addSubview(label)
        
        return cell
    }
}


// MARK: - ImageLoaderDelegate

extension ViewController: ImageLoaderDelegate {
    
    func imageLoader(_ loader: ImageLoader, didLoadImages images: [UIImage]) {
        
        self.imagesQueue = images
        self.reloadCollectionView()
        
        DispatchQueue.main.async {
            self.backgroundImageView.image = images[Int.random(in: 0..<self.imagesQueue.count)]
        }
    }
    
    func imageLoader(_ loader: ImageLoader, didFailWithError error: Error) {
        
        print("Failed to load images: \(error)")
    }
}


// MARK: - Other Methods

extension ViewController {
    
    func reloadCollectionView() {
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    func setNewBackgroundImage(_ targetImage: UIImage) {
        
        //Use debouncing technique to address frequent method calls and its impact on animation appearance
        transitionWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            UIView.transition(with: self?.backgroundImageView ?? UIView(),
                              duration: 0.1,
                              options: .transitionCrossDissolve,
                              animations: {
                                self?.backgroundImageView.image = targetImage
                              }, completion: nil)
        }
        transitionWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }
}
