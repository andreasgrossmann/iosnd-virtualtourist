//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Andreas on 2/11/16.
//  Copyright © 2016 Andreas. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    // MARK: Outlets
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteBar: UIToolbar!
    
    // MARK: Properties
    
    var deleteBarVisible = false
    
    // MARK: Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addAnnotation))
        longPressGestureRecognizer.minimumPressDuration = 0.5
        
        view.addGestureRecognizer(longPressGestureRecognizer)
        

        
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
            let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            mapView.addAnnotation(annotation)
            
            print(self.mapView.annotations.count)
            
        }

    }
    

    // Pin tapped
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if deleteBarVisible == true {
            
            // Remove annotation
            
            print("Pin Tapped")
            performUIUpdatesOnMain {
                self.mapView.removeAnnotation(view.annotation!)
            }
            
        } else {
            
            // Take user to photo album
            
            print("Pin Tapped")
            let selectedLoc = view.annotation
            print(selectedLoc?.coordinate as Any)
            
            performSegue(withIdentifier: "ShowCollectionView", sender: self)
            
        }
        
    }



}

