//
//  MapViewController.swift
//  MyPlaces
//
//  Created by Andrew Boldyrev on 13.06.2020.
//  Copyright © 2020 Andrew Boldyrev. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol MapViewControllerDelegate {
    func getAddress(_ address: String?)
}

class MapViewController: UIViewController {
    
    let mapManager = MapManager()
    var mapViewControllerDelegate: MapViewControllerDelegate?
    var place = Place()

    let annotationIdentifier = "annotationIdentifier"
    var incomeSegueIdentifier = ""
    
    var placeCoordinate: CLLocationCoordinate2D?
    var directionsArray: [MKDirections] = []
    var previousLocation: CLLocation? {
        didSet {
            mapManager.startTrakingUserLocation(for: mapVIew,
                                                and: previousLocation) { (currentLocation) in
                                                    self.previousLocation = currentLocation
                                                    
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.mapManager.showUserLocation(mapVIew: self.mapVIew)
                                                    }
            }
        }
    }
    
    @IBOutlet weak var mapVIew: MKMapView!
    @IBOutlet weak var mapMarkerImage: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var distanseLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addressLabel.text = ""
        mapVIew.delegate = self
        setupMapView()
    }

    @IBAction func centerViewInUserLocation() {
        mapManager.showUserLocation(mapVIew: mapVIew)
    }
    @IBAction func doneButtonPressed() {
        mapViewControllerDelegate?.getAddress(addressLabel.text)
        dismiss(animated: true)
    }
    
    @IBAction func closeVC() {
        dismiss(animated: true)
    }
    @IBAction func goButtonPressed() {
        mapManager.getDirections(for: mapVIew) { (location) in
            self.previousLocation = location
        }
        distanseLabel.isHidden = false
        timeLabel.isHidden = false
    }
    
    private func setupMapView() {
        
        goButton.isHidden = true
        distanseLabel.isHidden = true
        timeLabel.isHidden = true
        
        mapManager.checkLocationSevices(mapVIew: mapVIew, segueIdentifier: incomeSegueIdentifier) {
            mapManager.locationManager.delegate = self
        }
        
        if incomeSegueIdentifier == "showPlace"{
            mapManager.setupPlacemark(place: place, mapVIew: mapVIew)
            mapMarkerImage.isHidden = true
            addressLabel.isHidden = true
            doneButton.isHidden = true
            goButton.isHidden = false
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !(annotation is MKUserLocation) else {  return nil }
        
        var annotationView = mapVIew.dequeueReusableAnnotationView(withIdentifier: "annotationIdentifier") as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.canShowCallout = true
        }
        
        if let imageData = place.imageData {
           
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = UIImage(data: imageData)
            annotationView?.rightCalloutAccessoryView = imageView
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let center = mapManager.getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        
        if incomeSegueIdentifier == "ShowPlace" && previousLocation != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.mapManager.showUserLocation(mapVIew: self.mapVIew)
            }
        }
        
        geocoder.cancelGeocode()
        
        geocoder.reverseGeocodeLocation(center) { (placemarks, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }
            
            let placemark = placemarks.first
            let streetName = placemark?.thoroughfare
            let buildNumber = placemark?.subThoroughfare
            
            DispatchQueue.main.async {
                
                if streetName != nil && buildNumber != nil {
                    self.addressLabel.text = "\(streetName!), \(buildNumber!)"
                } else  if streetName != nil {
                    self.addressLabel.text = "\(streetName!)"
                } else {
                    self.addressLabel.text = ""
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .green
        return renderer
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        mapManager.checkLocationAuthorization(mapVIew: mapVIew, segueIdentifier: incomeSegueIdentifier)
    }
}
