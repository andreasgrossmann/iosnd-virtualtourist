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
        
        
        
//        // create fetch request to load photos
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
//        do {
//            if let photos = try? stack.context.fetch(fetchRequest) as! [Photo] {
//                
//                self.photos = photos
//                
//            }
//        }
        
        
        
        
        
        
        
        
        // See if we have photos for this location
        do {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
            let predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
            fetchRequest.predicate = predicate
            if let photos = try stack.context.fetch(fetchRequest) as? [Photo] {
                
                // Sort photos
                let sortedPhotos = photos.sorted { $0.url! < $1.url! }
                
                self.photos = sortedPhotos
                
                print("Photos Count: \(self.photos.count)")
            }
        } catch let error as NSError {
            print("failed to get pin by object id")
            print(error.localizedDescription)
            return
        }
        
        
        
        
        
        
        
        

        // If there are no photos for this location, get them from Flickr
        
        if photos.count == 0 {
            
//            print(pin)
//            print(photos)
            
            // Get image URLs from Flickr

            FlickrClient.sharedInstance().getFlickrPhotos(pin: pin) { (photos, error) in
                
                print("ATTENTION: GET PHOTO URLS")
                
                guard error == nil else {
                    print(error!)
                    return
                }
                
                
                
                
                if let photos = photos {
                    
                    // Sort photos
                    let sortedPhotos = photos.sorted { $0.url! < $1.url! }
                    
                    // populate photos array with urls
                    
                    performUIUpdatesOnMain {
                        self.photos = sortedPhotos
//                        self.stack.save()
//                        print("URLS SAVED")
//                        print(self.photos)
                    }
                    
                    
                    // assign pin for this location to each photo url
                    
                    for photo in photos {
                        photo.pin = self.pin
                    }
                    
                    
                    performUIUpdatesOnMain {
                        if self.photos.count == 0 {
                            print("no photos found")
                            // TODO: Display this in the view
                        }
                    }
                    
                    performUIUpdatesOnMain {
                        self.photoAlbumCollectionView.reloadData()
                    }
                    

//                    print(photos)
                    
            
                    
                } else {
                    
                    print("error")
                    
                }
                
            }

            
        }
        
        

    }
    
    
    
    
    // MARK: Actions
    
    @IBAction func bottomBarButtonPressed(_ sender: Any) {
        
        if selectedIndexes.isEmpty {
            // remove photos from pin managed object
            pin.removePhotos(context: stack.context)
            // remove photos from
            photos.removeAll(keepingCapacity: true)
            photoAlbumCollectionView.reloadData()
//            // get new photos
//            getNewCollectionOfPhotos()
        } else {
            deletePhotos()
        }
        
        updateBottomButton()
        
    }
    
    
    
    
    // MARK: Delete Photos
    
    func deletePhotos() {
        var photosMarkedForDeletion = [Photo]()
        
        
        
        for indexPath in selectedIndexes {
            let photoObject = self.photos[indexPath.row]
            self.photos.remove(at: indexPath.row)
            self.photoAlbumCollectionView.deleteItems(at: [indexPath])
            photosMarkedForDeletion.append(photoObject)
        }
        
        
        
        
        if self.photos.count == 0 {
            performUIUpdatesOnMain {
                //                self.noImagesLabel.text = "Album is Empty"
                //                self.noImagesLabel.hidden = false
                //                self.stack.save()
            }
        }
        
        
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
    

    
    
    // Prepare cells with meme images and text
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VirtualTouristCollectionViewCell", for: indexPath) as! VirtualTouristCollectionViewCell
        
        let photoObject = photos[indexPath.item]
        
        
        performUIUpdatesOnMain {
            cell.virtualTouristCollectionImage.image = UIImage(named: "placeholder")
        }
        
        
        
        if photos[indexPath.item].data == nil {
            
            

            print("photo data seems to be nil")
//            for photo in photos {
//                print("photo data: \(photo.data)")
//            }
        
        
            // Get image data from Flickr
                
            FlickrClient.sharedInstance().downloadImage(photos: photoObject) { (data, error) in
                
                print("ATTENTION: DOWNLOAD IMAGES")
//                print("photoObject: \(photoObject)")
                
                if (data != nil) {
                    
//                    print(data!)
                    
                    performUIUpdatesOnMain {
                        cell.virtualTouristCollectionImage.image = UIImage(data: data!)
                        
                        
                        self.photos[indexPath.item].data = data as NSData?
                        
//                        print(self.photos[indexPath.item])
                        
//                        self.photos[indexPath.item].pin = self.pin

//                        print([indexPath.item])

                        self.stack.save()
                        print("Photo data saved")
                        
                        
                    }
                        
                }
                
                
            }
                
//         print("House: \(self.photos)")
            
        } else {
            
            performUIUpdatesOnMain {
                cell.virtualTouristCollectionImage.image = UIImage(data: self.photos[indexPath.item].data! as Data)
            }
            
        }

        
        
        return cell
    }
    
    // item selected
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! VirtualTouristCollectionViewCell
        
        
        if let index = selectedIndexes.index(of: indexPath) {
            selectedIndexes.remove(at: index)
            cell.virtualTouristCollectionImage.alpha = 1.0
        } else {
            selectedIndexes.append(indexPath)
            cell.virtualTouristCollectionImage.alpha = 0.2
        }
        
        updateBottomButton()
        
        
    }
    
    
    
    
    
    
    
    
    


    
    
    
    
    
    
    
    
    // MARK: Update Bottom Button
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            bottomBarButton.title = "Remove Selected Pictures"
            bottomBarButton.tintColor = UIColor.red
        } else {
            bottomBarButton.title = "New Collection"
            bottomBarButton.tintColor = UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
        }
    }
    
    
    
    
    
    
    
    
    
    // WHEN THE NEW COLLECTION BUTTON AT THE BOTTOM IS PRESSED, WE ALSO INITIATE A DOWNLOAD FROM FLICKR



}
