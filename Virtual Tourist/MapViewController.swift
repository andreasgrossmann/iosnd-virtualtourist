//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Andreas on 2/11/16.
//  Copyright © 2016 Andreas. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {

    // MARK: Outlets
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteBar: UIToolbar!
    
    // MARK: Properties
    
    var pin: Pin!
    
    var stack: CoreDataStack!
    
    var deleteBarVisible = false
    
    
    

    
    
    
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        
        // Get core data stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        stack = delegate.stack
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set gesture recognizer
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addAnnotation))
        longPressGestureRecognizer.minimumPressDuration = 0.5
        view.addGestureRecognizer(longPressGestureRecognizer)
        
        
        
        loadPins()
        

        
    }
    
    // MARK: Actions
    
    @IBAction func editPressed(_ sender: Any) {
        
        if deleteBarVisible == false {
            
            UIView.animate(withDuration: 0.2, animations: {
                self.mapView.frame.origin.y -= self.deleteBar.frame.height
            })
            
            editButton.title = "Done"
            
            deleteBarVisible = true
            
        } else {
            
            UIView.animate(withDuration: 0.2, animations: {
                self.mapView.frame.origin.y += self.deleteBar.frame.height
            })
            
            editButton.title = "Edit"
            
            deleteBarVisible = false
            
        }
        
    }
    
    
    
    // Add map annotation on long press
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        
        if gestureRecognizer.state == UIGestureRecognizerState.began {
        
            let touchPoint = gestureRecognizer.location(in: mapView)
            let touchMapCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchMapCoordinates
            mapView.addAnnotation(annotation)
            
            print(self.mapView.annotations.count)
            
            pin = Pin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, context: stack.context)
            
        }
        
        stack.save()

    }
    
    
    
    
    
    
    
    func loadPins() {
        
        // create fetch request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        do {
            if let pins = try? stack.context.fetch(fetchRequest) as! [Pin] {
                
                // create annotations for pins
                for pin in pins {
                    let latitude = CLLocationDegrees(pin.latitude)
                    let longitude = CLLocationDegrees(pin.longitude)
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    let newAnotation = MKPointAnnotation()
                    newAnotation.coordinate = coordinate
                    mapView.addAnnotation(newAnotation)
                }

            }
        }
    }
    
    
    
    
    
    
    
    // NOTE: WHEN YOU TAP THE PIN TO GO TO THE PHOTO ALBUM VIEW AND THEN RETURN TO MAP VIEW, NOTHING HAPPENS WHEN YOU TAP A PIN
    

    // Pin tapped
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if deleteBarVisible == true {
            
            

            
            // Find this pin
            var pin: Pin!
            do {
                let thisPin = view.annotation as AnyObject
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
                let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [thisPin.coordinate.latitude, thisPin.coordinate.longitude])
                fetchRequest.predicate = predicate
                let pins = try stack.context.fetch(fetchRequest) as? [Pin]
                pin = pins![0]
            } catch let error as NSError {
                print("failed to get pin by object id")
                print(error.localizedDescription)
                return
            }
            
            
            
            
            // Remove annotation from mapView
            
            performUIUpdatesOnMain {
                self.mapView.removeAnnotation(view.annotation!)
            }
            
            
            
            
            stack.context.delete(pin)
            stack.save()
            
        } else {
            
            // Take user to photo album
            
            performSegue(withIdentifier: "ShowCollectionView", sender: self)
            
        }
        
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowCollectionView") {
            let viewController = segue.destination as! PhotoAlbumViewController
            viewController.pin = pin
        }
    }



}

