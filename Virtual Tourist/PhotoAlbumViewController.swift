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


        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // calculate layout for collection view
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        // update collection view layout
        let size = floor(photoAlbumCollectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: size, height: size)
        photoAlbumCollectionView.collectionViewLayout = layout
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        

        // Check if we already have photos for this location
        
        if photos.count == 0 {
            
            print(pin)
            print(photos)
            

            FlickrClient.sharedInstance().getFlickrPhotos(pin: pin) { (photos, error) in
                
                print("ATTENTION: GET PHOTO URLS")
                
                guard error == nil else {
                    print(error!)
                    return
                }
                
                
                
                if let photos = photos {
                    
                    for photo in photos {
                        photo.pin = self.pin
                    }
                    
                    performUIUpdatesOnMain {
                        self.photos = photos
                        self.stack.save()
                        print("URLS SAVED")
                        print(self.photos)
                    }
                    performUIUpdatesOnMain {
                        if self.photos.count == 0 {
                            print("no photos found")
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
        
        let photoObject = photos[indexPath.row]
        
        
        performUIUpdatesOnMain {
            cell.virtualTouristCollectionImage.image = UIImage(named: "placeholder")
        }
        
        
        
        if photos[indexPath.item].data == nil {

        
        
            // Get image data from Flickr
                
            FlickrClient.sharedInstance().downloadImage(photos: photoObject) { (data, error) in
                
                print("ATTENTION: DOWNLOAD IMAGES")
                
                if (data != nil) {
                    
                    print(data!)
                    
                    performUIUpdatesOnMain {
                        cell.virtualTouristCollectionImage.image = UIImage(data: data!)
                    }
                        
                }
                
                
            }
                
            
            
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
