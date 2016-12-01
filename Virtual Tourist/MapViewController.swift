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
        
        // Set gesture recognizer
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addAnnotation))
        longPressGestureRecognizer.minimumPressDuration = 0.5
        view.addGestureRecognizer(longPressGestureRecognizer)
        
        // Restore last known map region
        loadMostRecentMapRegion()
        
        // Get core data stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        stack = delegate.stack
        
        // Load pins
        performUIUpdatesOnMain {
            self.loadPins()
        }
        
    }

    // MARK: Actions
    
    @IBAction func editPressed(_ sender: Any) {
        
        if !deleteBarVisible {
            
            performUIUpdatesOnMain {
                
                // Slide map up to reveal delete bar
                
                UIView.animate(withDuration: 0.2, animations: {
                    self.mapView.frame.origin.y -= self.deleteBar.frame.height
                })
                
                self.editButton.title = "Done"
                self.deleteBarVisible = true
                
            }
            
        } else {
            
            performUIUpdatesOnMain {
                
                // Slide map down to hide delete bar
                
                UIView.animate(withDuration: 0.2, animations: {
                    self.mapView.frame.origin.y += self.deleteBar.frame.height
                })
                
                self.editButton.title = "Edit"
                self.deleteBarVisible = false
                
            }
            
        }
        
    }

    // MARK: Save and restore most recent map region
    
    func saveMostRecentMapRegion() {
        let defaults = UserDefaults.standard
        defaults.set(mapView.region.center.latitude, forKey: "MapLatitude")
        defaults.set(mapView.region.center.longitude, forKey: "MapLongitude")
        defaults.set(mapView.region.span.latitudeDelta, forKey: "MapLatitudeDelta")
        defaults.set(mapView.region.span.longitudeDelta, forKey: "MapLongitudeDelta")
    }
    
    func loadMostRecentMapRegion() {
        let defaults = UserDefaults.standard
        if let mapLat = defaults.object(forKey: "MapLatitude") as? CLLocationDegrees,
            let mapLon = defaults.object(forKey: "MapLongitude") as? CLLocationDegrees,
            let mapLatDelta = defaults.object(forKey: "MapLatitudeDelta") as? CLLocationDegrees,
            let mapLonDelta = defaults.object(forKey: "MapLongitudeDelta") as? CLLocationDegrees {
            mapView.region.center = CLLocationCoordinate2D(latitude: mapLat, longitude: mapLon)
            mapView.region.span = MKCoordinateSpanMake(mapLatDelta, mapLonDelta)
        }
    }

    // MARK: Add map annotation on long press
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer) {
        
        if gestureRecognizer.state == UIGestureRecognizerState.began {
        
            let touchPoint = gestureRecognizer.location(in: mapView)
            let touchMapCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchMapCoordinates
            mapView.addAnnotation(annotation)

            pin = Pin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, context: stack.context)

        }
        
        performUIUpdatesOnMain {
            self.stack.save()
        }

    }

    // MARK: Load pins
    
    func loadPins() {
        
        // Create fetch request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")

        // Try to fetch pins
        do {
            if let pins = try stack.context.fetch(fetchRequest) as? [Pin] {
                
                // Create annotations for pins
                for pin in pins {
                    let latitude = CLLocationDegrees(pin.latitude)
                    let longitude = CLLocationDegrees(pin.longitude)
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    let newAnotation = MKPointAnnotation()
                    newAnotation.coordinate = coordinate
                    mapView.addAnnotation(newAnotation)
                }

            }
        } catch let error as NSError {
            print(error.localizedDescription)
            return
        }
    }

    // MARK: Save map region when it changes
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMostRecentMapRegion()
    }

    // MARK: Pin tapped
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // Deselect pin
        mapView.deselectAnnotation(view.annotation, animated: false)

        // Find pin
        
        let thisPin = view.annotation as AnyObject
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [thisPin.coordinate.latitude, thisPin.coordinate.longitude])
        fetchRequest.predicate = predicate

        do {
            if let pins = try stack.context.fetch(fetchRequest) as? [Pin] {
                pin = pins[0]
            }
        } catch let error as NSError {
            print(error.localizedDescription)
            return
        }

        // If deleteBar is visible, delete pin and save
        guard !self.deleteBarVisible else {
            performUIUpdatesOnMain {
                mapView.removeAnnotation(view.annotation!)
                self.stack.context.delete(self.pin)
                self.stack.save()
            }
            return
        }
        
        // Take user to photo album
            
        performUIUpdatesOnMain {
            self.performSegue(withIdentifier: "ShowCollectionView", sender: self)
        }

    }
    
    // Pass selected pin along with segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowCollectionView") {
            let viewController = segue.destination as! PhotoAlbumViewController
            viewController.pin = pin
        }
    }

}
