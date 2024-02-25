//
//  MainViewViewModel.swift
//  Televator
//
//  Created by Nathan Barta on 2/19/24.
//

import SwiftUI
import CoreLocation
import CoreMotion
import CoreTelephony
import Combine
import SwiftyPing

final public class MainViewViewModel: NSObject, ObservableObject {
  @Published var gpsSignalStrength: Double = .zero
  @Published var gpsTimeSinceLastUpdate: TimeInterval = .zero
  @Published var zAcceleration: Double = .zero
  @Published var mMagnetometer: Double = .zero
  @Published var zGravity: Double = .zero
  @Published var barometric: Double = .zero
  @Published var latencyHistory: [TimeInterval] = .init()
  
  private var lastTimeStamp: Date = .distantPast {
    willSet(newTimeStamp) {
      gpsTimeSinceLastUpdate = newTimeStamp.timeIntervalSince(lastTimeStamp)
    }
  }
  
  @Published var errorString: String = .init()

  private lazy var locationManager = CLLocationManager()
  private lazy var motionManager = CMMotionManager()
  private lazy var altimeterManager = CMAltimeter()
  
  override init() {
    super.init()

    locationManager.delegate = self
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.showsBackgroundLocationIndicator = true
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    locationManager.pausesLocationUpdatesAutomatically = false
    locationManager.activityType = .otherNavigation // .fitness also pretty good
        
    switch locationManager.authorizationStatus {
      case .authorizedWhenInUse:
        locationManager.requestAlwaysAuthorization()
        break
      case .notDetermined:
        locationManager.requestAlwaysAuthorization()
        break
      case .denied, .restricted:
        fatalError("Location denied")
        break
      default:
        break
    }
    
    switch locationManager.accuracyAuthorization {
      case .fullAccuracy:
        print("isAuthorizedForPreciseLocation = true")
      case .reducedAccuracy:
        print("isAuthorizedForPreciseLocation = false")
      @unknown default:
        fatalError("Unknown accuracy authorization")
    }
    
    var config = PingConfiguration(interval: 1.0, with: 5.0)
    config.handleBackgroundTransitions = true
    
    let pinger = try? SwiftyPing(host: "1.1.1.1", configuration: config, queue: DispatchQueue.global())
    pinger?.observer = { (response) in
      let duration = response.duration
      DispatchQueue.main.async {
        self.latencyHistory.append(duration)
      }
      print(duration)
    }
    
    pinger?.finished = { (result) in
      print("Result")
    }

    try? pinger?.startPinging()
    
//    locationManager.startUpdatingLocation()
    
//    motionManager.startAccelerometerUpdates(to: .main) { data, error in
//      if let data = data {
//        self.zAcceleration = -9.81 * data.acceleration.z
//      }
//    }
    
//    motionManager.startMagnetometerUpdates(to: .main) { data, error in
//      if let data = data {
//        self.mMagnetometer = max(data.magneticField.x, data.magneticField.y, data.magneticField.z, .zero)
//      }
//    }
//    
//    motionManager.startDeviceMotionUpdates(to: .main) { data, error in
//      if let data = data {
//        self.zGravity = data.gravity.z
//      }
//    }
//
//    altimeterManager.startRelativeAltitudeUpdates(to: .main) { data, error in
//      if let data = data {
//        self.barometric = data.pressure.doubleValue
//      }
//    }
  }
}

// MARK: - Location
extension MainViewViewModel: CLLocationManagerDelegate {
  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    gpsSignalStrength = locations.last!.horizontalAccuracy
    lastTimeStamp = .now
    print(gpsSignalStrength.description)
  }
  
  public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    locationManager.stopUpdatingLocation()
    errorString = error.localizedDescription
    print(errorString)
  }
}
