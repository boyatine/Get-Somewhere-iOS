//
//  ViewController.swift
//  Get Somewhere
//
//  Created by Wonsug E on 4/3/19.
//  Copyright © 2019 Wonsug E. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    @IBOutlet weak var map: MKMapView!
    var locationManager = CLLocationManager()
    var savedLoc : [LOC] = []
    
    let MIN_RANGE = -0.02
    let MAX_RANGE = 0.02
    let GOAL_RANGE = 0.0007
    
    let latDelta: CLLocationDegrees = 0.05
    let lonDelta: CLLocationDegrees = 0.05
    
    var initialized = false
    
    var goalAddress = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        getItems()
    }
    
    func getItems() {
        if let context =
            (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext {
            if let coreDataLoc = try? context.fetch(LOC.fetchRequest()) as? [LOC] {
                savedLoc = coreDataLoc
            }
        }
    }
    
    func setNewLocation(location: CLLocation) {
        if let context =
            (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext {
            let toSaveLoc = LOC(entity: LOC.entity(), insertInto: context )
            
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            
            
            var randomN = Double.random(in: MIN_RANGE ... MAX_RANGE)
            toSaveLoc.savedLat = lat + randomN
            randomN = Double.random(in: MIN_RANGE ... MAX_RANGE)
            toSaveLoc.savedLon = lon + randomN
            toSaveLoc.done = false
            
            try? context.save()
            
            getItems()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let initialPosition: CLLocation = locations[0]
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let region = MKCoordinateRegion(center: initialPosition.coordinate, span: span)
        
        if (savedLoc.count == 0) {
            setNewLocation(location: initialPosition)
            
            CLGeocoder().reverseGeocodeLocation(initialPosition) {(placemarks, error) in
                if error != nil {
                    print(error!)
                }
                    
                else {
                    if let placemark = placemarks?[0] {
                        var subThoroughfare = "";
                        if placemark.subThoroughfare != nil {
                            subThoroughfare = placemark.subThoroughfare!
                        }
                        
                        var thoroughfare = ""
                        if placemark.thoroughfare != nil {
                            thoroughfare = placemark.thoroughfare!
                        }
                        
                        var sublocality = ""
                        if placemark.subLocality != nil {
                            sublocality = placemark.subLocality!
                        }
                        
                        var subadministrativearea = ""
                        if placemark.subAdministrativeArea != nil {
                            subadministrativearea = placemark.subAdministrativeArea!
                        }
                        
                        var postalcode = ""
                        if placemark.postalCode != nil {
                            postalcode = placemark.postalCode!
                        }
                        
                        let alert = UIAlertController(title: "Get to " + subThoroughfare + " " + thoroughfare + " " + sublocality + " " + subadministrativearea + " " + postalcode, message: "", preferredStyle: .alert)
                        
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        
                        self.present(alert, animated: true)
                        
                    
                    }
                }
            }
        }

        else if (!savedLoc[0].done) {
            let goalPin = MKPointAnnotation()
            goalPin.title = "Your goal location"
            goalPin.coordinate.latitude = savedLoc[0].savedLat
            goalPin.coordinate.longitude = savedLoc[0].savedLon
            map.addAnnotation(goalPin)
            
            let currentPin = MKPointAnnotation()
            currentPin.title = "Your current location"
            currentPin.coordinate.latitude = initialPosition.coordinate.latitude
            currentPin.coordinate.longitude = initialPosition.coordinate.longitude
            map.addAnnotation(currentPin)
            
            self.map.setRegion(region, animated: true)
            
            if (abs(initialPosition.coordinate.latitude - savedLoc[0].savedLat) < GOAL_RANGE && abs(initialPosition.coordinate.longitude - savedLoc[0].savedLon) < GOAL_RANGE ) {
                if let context =
                    (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext {
                    let toSaveLoc = LOC(entity: LOC.entity(), insertInto: context)
                    toSaveLoc.done = true
                    try? context.save()
                    getItems()
                }
                
                if let context =
                    (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext {
                    let toDelete = savedLoc[0]
                    context.delete(toDelete)
                    try? context.save()
            }
            
        }
        
        else if (savedLoc[0].done) {
            setNewLocation(location: initialPosition)
        }
        }
    }
}
