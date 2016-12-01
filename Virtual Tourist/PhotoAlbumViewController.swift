//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Andreas on 11/11/16.
//  Copyright © 2016 Andreas. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

    // MARK: Properties
    
    var pin: Pin!
    var photos = [Photo]()
    var stack: CoreDataStack!
    var selectedIndexes = [IndexPath]()

    // MARK: Outlets
    
    @IBOutlet weak var photoAlbumMapView: MKMapView!
    @IBOutlet weak var photoAlbumCollectionView: UICollectionView!
    @IBOutlet weak var noPhotosLabel: UILabel!
    @IBOutlet weak var bottomBar: UIToolbar!
    @IBOutlet weak var bottomBarButton: UIBarButtonItem!

    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Get core data stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        stack = delegate.stack

        // Set map region and show location pin
        
        if let photoAlbumMapView = photoAlbumMapView {
            
            let mapCenter = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
            let mapSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let mapRegion = MKCoordinateRegionMake(mapCenter, mapSpan)
            photoAlbumMapView.setRegion(mapRegion, animated: true)
            photoAlbumMapView.isUserInteractionEnabled = false
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = mapCenter
            photoAlbumMapView.addAnnotation(annotation)

        }

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Calculate collection view layout
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        // Update collection view layout
        let size = floor(photoAlbumCollectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: size, height: size)
        photoAlbumCollectionView.collectionViewLayout = layout
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Hide no photos label
        noPhotosLabel.isHidden = true

        // See if we already have photos for this location
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        fetchRequest.predicate = predicate

        do {
            if let photos = try stack.context.fetch(fetchRequest) as? [Photo] {
                
                // Sort photos
                let sortedPhotos = photos.sorted { $0.url! < $1.url! }
                
                self.photos = sortedPhotos

            }
        } catch let error as NSError {
            print(error.localizedDescription)
            return
        }

        // If there are no photos for this location, get them from Flickr
        
        if photos.count == 0 {
            
            getNewCollectionOfPhotos()

        }

    }

    // MARK: Actions
    
    @IBAction func bottomBarButtonPressed(_ sender: Any) {
        
        // If no photos are selected, get a new collection of photos
        if selectedIndexes.isEmpty {
            // Remove photos from pin
            pin.removePhotos(context: stack.context)
            // Empty photos array and reload collection view
            photos.removeAll(keepingCapacity: true)
            photoAlbumCollectionView.reloadData()
            // Get new photos
            getNewCollectionOfPhotos()
        } else {
            // If photos are selected, delete them
            performUIUpdatesOnMain {
                self.deletePhotos()
            }
        }
        
        performUIUpdatesOnMain {
            self.updateBottomButton()
        }
        
    }
    
    // MARK: Update bottom button (delete photos or get new collection)
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            // Photos selected
            bottomBarButton.title = "Remove Selected Pictures"
            bottomBar.barTintColor = UIColor.red
            bottomBarButton.tintColor = UIColor.white
        } else {
            // No photos selected
            bottomBarButton.title = "New Collection"
            bottomBar.barTintColor = UIColor.white
            bottomBarButton.tintColor = UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
        }
    }

    // MARK: Get new collection of photos
    
    func getNewCollectionOfPhotos() {
        
        noPhotosLabel.isHidden = true
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Show activity indicator
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
        activityIndicator.color = UIColor.darkGray
        activityIndicator.center = self.view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)

        // Get photo URLs from Flickr
        
        FlickrClient.sharedInstance().getPhotoURLs(pin: pin) { (photos, error) in
            
            // Was there an error?
            guard error == nil else {
                print(error!)
                return
            }

            if let photos = photos {
                
                // Sort photos
                let sortedPhotos = photos.sorted { $0.url! < $1.url! }
                
                // Populate photos array with URLs
                
                performUIUpdatesOnMain {

                    self.photos = sortedPhotos

                    // Assign location pin to each photo URL
                    
                    for photo in photos {
                        photo.pin = self.pin
                    }
                    
                    // If there are no photos for this location, display a message
                    if self.photos.count == 0 {
                        self.noPhotosLabel.text = "No photos found 🙁"
                        self.noPhotosLabel.isHidden = false
                    }

                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    
                    activityIndicator.stopAnimating()
                    
                    self.photoAlbumCollectionView.reloadData()

                }

            }

        }

    }

    // MARK: Delete Photos
    
    func deletePhotos() {
        
        // Photos to be deleted
        var photosMarkedForDeletion = [Photo]()

        photoAlbumCollectionView.performBatchUpdates({
                
            // Sort selected photos
            let sortedIndexes = self.selectedIndexes.sorted {$0.item > $1.item}
            
            for indexPath in sortedIndexes {
                let photoObject = self.photos[indexPath.item]
                // Remove photo from photos array
                self.photos.remove(at: indexPath.item)
                // Remove photo from collection view
                self.photoAlbumCollectionView.deleteItems(at: [indexPath])
                // Append photo to array of photos to be deleted
                photosMarkedForDeletion.append(photoObject)
            }
            
        }, completion: { (completed) in
            
            // If there are no photos left in the collection, display a message
            if self.photos.count == 0 {
                performUIUpdatesOnMain {
                    self.noPhotosLabel.text = "There are no photos in this album 🙁"
                    self.noPhotosLabel.isHidden = false
                    self.stack.save()
                }
            }

        })

        // Delete photos
        for photo in photosMarkedForDeletion {
            stack.context.delete(photo)
            stack.save()
        }
        
        selectedIndexes = [IndexPath]()

    }

    // MARK: Collection view
    
    // Set number of items
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }

    // Prepare cells
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VirtualTouristCollectionViewCell", for: indexPath) as! VirtualTouristCollectionViewCell

        // Show a random emoji placeholder photo
        
        performUIUpdatesOnMain {
            
            let randomNumber = arc4random_uniform(11)
            var placeholder = ""

            switch randomNumber {
            case 0:
                placeholder = "volcano"
            case 1:
                placeholder = "tent"
            case 2:
                placeholder = "nightsky"
            case 3:
                placeholder = "mountain"
            case 4:
                placeholder = "castle"
            case 5:
                placeholder = "mountainsun"
            case 6:
                placeholder = "ship"
            case 7:
                placeholder = "statue"
            case 8:
                placeholder = "citynight"
            case 9:
                placeholder = "citysun"
            case 10:
                placeholder = "rollercoaster"
            default:
                placeholder = "mountain"
            }

            cell.virtualTouristCollectionImage.image = UIImage(named: placeholder)
            
        }
        
        let photoObject = photos[indexPath.item]
        
        // Do we have photo data?

        if photoObject.data == nil {

            UIApplication.shared.isNetworkActivityIndicatorVisible = true

            // Get photo data from Flickr
                
            FlickrClient.sharedInstance().downloadPhotos(photos: photoObject) { (data, error) in
                
                // Was there an error?
                guard error == nil else {
                    print(error!)
                    return
                }

                if (data != nil) {

                    performUIUpdatesOnMain {

                        cell.virtualTouristCollectionImage.image = UIImage(data: data!)
                        
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false

                        // Make sure index is within range

                        if indexPath.item <= self.photos.count {
                            
                            self.photos[indexPath.item].data = data as NSData?
                            
                        }
                        
                        // Save
                        self.stack.save()

                    }
                        
                }

            }

        } else {
            
            performUIUpdatesOnMain {
                cell.virtualTouristCollectionImage.image = UIImage(data: self.photos[indexPath.item].data as! Data)
            }

        }

        performUIUpdatesOnMain {

            // Highlight selected images only
            
            if (self.selectedIndexes.contains(indexPath)) {
                cell.layer.backgroundColor = UIColor.red.cgColor
                cell.virtualTouristCollectionImage.alpha = 0.5
            } else {
                cell.layer.backgroundColor = UIColor.clear.cgColor
                cell.virtualTouristCollectionImage.alpha = 1.0
            }

        }

        return cell
    }
    
    // MARK: Photo tapped
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let cell = collectionView.cellForItem(at: indexPath) as! VirtualTouristCollectionViewCell

        // If photo is already selected
        if let index = selectedIndexes.index(of: indexPath) {
            
            performUIUpdatesOnMain {

                // Remove photo from array of selected photos
                self.selectedIndexes.remove(at: index)
                
                // Unmark photo
                cell.layer.backgroundColor = UIColor.clear.cgColor
                cell.virtualTouristCollectionImage.alpha = 1.0

            }
            
        } else {

            performUIUpdatesOnMain {

                // Add photo to array of selected photos
                self.selectedIndexes.append(indexPath)

                // Mark photo
                cell.layer.backgroundColor = UIColor.red.cgColor
                cell.virtualTouristCollectionImage.alpha = 0.5

            }
            
        }
        
        performUIUpdatesOnMain {
            self.updateBottomButton()
        }

    }

}
