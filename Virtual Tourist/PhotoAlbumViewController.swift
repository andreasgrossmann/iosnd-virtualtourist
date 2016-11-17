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
    
    
    
    
    
    // MARK: Outlets
    
    
    
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Get core data stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        stack = delegate.stack
        
        
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        
        // HERE WE SHOULD CHECK IF THERE ARE ALREADY PHOTOS SAVED FOR THIS LOCATION
        // IF YES, POPULATE THE COLLECTION VIEW WITH THEM
        // IF NOT, DOWNLOAD PHOTOS FROM FLICKR
        
        
        
        FlickrClient.sharedInstance().getFlickrPhotos(pin: pin) { (success, error) in
            
            if success! {
                
                print("success")
                
                
                // POPULATE COLLECTION VIEW WITH SAVED PHOTOS
                
                
                
                
            } else {
                
                print("error")
                
            }
            
        }
        
        
        
    }
    
    
    
    
    
    
    
    // Set number of items
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    
    // Prepare cells with meme images and text
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) //as! SentMemeCollectionViewCell

        
        
        return cell
    }
    
    // item selected
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
    }
    
    
    
    
    
    
    
    
    
    // WHEN THE NEW COLLECTION BUTTON AT THE BOTTOM IS PRESSED, WE ALSO INITIATE A DOWNLOAD FROM FLICKR



}
