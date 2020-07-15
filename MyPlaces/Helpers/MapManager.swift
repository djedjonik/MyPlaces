//
//  MapManager.swift
//  MyPlaces
//
//  Created by Andrew Boldyrev on 24.06.2020.
//  Copyright © 2020 Andrew Boldyrev. All rights reserved.
//

import UIKit
import MapKit

class MapManager {
    
    let locationManager = CLLocationManager()
    
    private let regionInMeters = 1000.00
    private var directionsArray: [MKDirections] = []
    private var placeCoordinate: CLLocationCoordinate2D?
    
    // Маркер заведения
    func setupPlacemark(place: Place, mapVIew: MKMapView ) {
        
        guard let location = place.location else { return }
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }
            
            let placemark = placemarks.first
            
            let annotation = MKPointAnnotation()
            annotation.title = place.name
            annotation.subtitle = place.type
            
            guard let placemarkLocation = placemark?.location else { return }
            
            annotation.coordinate = placemarkLocation.coordinate
            self.placeCoordinate = placemarkLocation.coordinate
            
            mapVIew.showAnnotations([annotation], animated: true)
            mapVIew.selectAnnotation(annotation, animated: true)
        }
    }
   
    // Проверка доступности сервисов геолокации
    func checkLocationSevices(mapVIew: MKMapView, segueIdentifier: String, closure: () -> ()) {
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            checkLocationAuthorization(mapVIew: mapVIew, segueIdentifier: segueIdentifier)
            closure()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(title: "Location Services are Disabled",
                               messege: "To enable it go: Settings -> Privacy -> Location Sevices and turn On")
            }
        }
    }
    
    // Проверка авторизации приложения для использование сервисов геолокации
    func checkLocationAuthorization(mapVIew: MKMapView, segueIdentifier: String) {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            mapVIew.showsUserLocation = true
            if segueIdentifier == "getAddress" { showUserLocation(mapVIew: mapVIew)}
            break
        case .denied:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(
                    title: "Your Location is not available",
                    messege: "To give permission Go to: Settings -> MyPlaces -> Location")
            }
        break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            break
        case .authorizedAlways:
            break
        @unknown default:
            print("New case is available")
        }
    }
    
    // Фокус карты на местоположении пользователя
    func showUserLocation(mapVIew: MKMapView) {
        if let location = locationManager.location?.coordinate {
        let region = MKCoordinateRegion(center: location,
                                        latitudinalMeters: regionInMeters,
                                        longitudinalMeters: regionInMeters)
        mapVIew.setRegion(region, animated: true)
        }
    }
    
    // Строим маршрут от местоположения пользователя до заведения
    func getDirections(for mapVIew: MKMapView, previousLocation: (CLLocation) -> ()) {
        
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Error", messege: "Current location is not found")
            return
        }
        
        locationManager.startUpdatingLocation()
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
        
        guard let request = createDirectionsRequest(from: location) else {
             showAlert(title: "Error", messege: "Destination is not found")
         return
        }
        
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions, mapVIew: mapVIew)
        
        directions.calculate { (response, error) in
            
            if let error = error {
                print(error)
                return
            }
            guard let response = response else {
                self.showAlert(title: "Error", messege: "Direction is not avilable")
                return
            }
            for route in response.routes {
                mapVIew.addOverlay(route.polyline)
                mapVIew.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                let distance = String(format: "%.1f", route.distance / 1000)
                let timeInterval = String(format: "%.1f", route.expectedTravelTime / 60)
                
                
//                self.distanseLabel.text = "Расстояние до места: \(distance) км."
//                self.timeLabel.text = "Вреемя в пути составит: \(timeInterval) мин."
            }
        }
    }
    
    // Настройка запроса для расчета маршрута
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        
        guard let destinationCoordinate = placeCoordinate else { return nil }
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    // Меняем отображаемую зону области карты в соответсвии с перемещением пользователя
    func startTrakingUserLocation(for mapVIew: MKMapView, and location:CLLocation?, closure: (_ currentLocation: CLLocation) -> ()) {
          
          guard let location = location else { return }
          let center = getCenterLocation(for: mapVIew)
          guard center.distance(from: location) > 50 else { return }
          
          closure(center)
      }
    
    // Сброс всех ранее построенных маршрутов перед построением нового
    func resetMapView(withNew directions: MKDirections, mapVIew: MKMapView) {
        
        mapVIew.removeOverlays(mapVIew.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel() }
        directionsArray.removeAll()
    }
    
    // Отображение центра отображаемой области карты
    func getCenterLocation(for mapVIew: MKMapView) -> CLLocation {
           
           let latitude = mapVIew.centerCoordinate.latitude
           let longitude = mapVIew.centerCoordinate.longitude
           
           return CLLocation(latitude: latitude, longitude: longitude)
       }
    
    private func showAlert(title: String, messege: String) {
        
        let alert = UIAlertController(title: title, message: messege, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(okAction)
        
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert + 1
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alert, animated: true)
    }
}
