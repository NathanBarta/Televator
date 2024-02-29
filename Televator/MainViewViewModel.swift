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

let PING_INTERVAL: TimeInterval = 1.0
let WINDOW_WIDTH: Int = 60

public struct LatencyRecord: Identifiable {
  public let id: Int
  public let latency: TimeInterval
}

public struct SignalRecord: Identifiable {
  public let id: Int
  public let signal: Int
}

final public class MainViewViewModel: NSObject, ObservableObject {
  @Published var latencyHistory: [LatencyRecord] = .init()
  @Published var signalHistory: [SignalRecord] = .init()
  @Published var rollingAvg: TimeInterval? = nil
  @Published var manualEnterElevatorIndex: Int?
  @Published var manualExitElevatorIndex: Int?
  @Published var windowFillingProgress: Float = .zero
  
  public var maxLatency: TimeInterval = .zero
  private var rawLatencyHistory: [TimeInterval] = .init()
  public var sampleIndex: Int = -1
  
  @Published var errorString: String = .init()

  override init() {
    super.init()

    // New ping occurs once previous comes back (rounded up to PING_INTERVAL if necessary)
    var config = PingConfiguration(interval: PING_INTERVAL, with: 5.0)
    config.handleBackgroundTransitions = true
    
    let pinger = try? SwiftyPing(host: "1.1.1.1", configuration: config, queue: DispatchQueue.global())
    pinger?.observer = { (response) in
      DispatchQueue.main.async {
        self.addLatencyReading(response)
      }
    }
    
    pinger?.finished = { (result) in
      print(result)
    }

    try? pinger?.startPinging()
  }
  
  private func addLatencyReading(_ p: PingResponse) {
    let sequenceNumber = p.sequenceNumber
    let duration = p.duration

    sampleIndex += 1
    rawLatencyHistory.append(duration)
    
    #if DEBUG
      print(sequenceNumber, duration)
    #endif
    
    if sequenceNumber > WINDOW_WIDTH - 1 {
      let (signals,_,_) = ThresholdingAlgo(y: rawLatencyHistory, lag: WINDOW_WIDTH, threshold: 4.0, influence: 1.0)
      latencyHistory.append(.init(id: Int(sequenceNumber) - WINDOW_WIDTH, latency: duration))
      signalHistory.append(.init(id: Int(sequenceNumber) - WINDOW_WIDTH, signal: signals.last!))
    } else {
      maxLatency = max(maxLatency, duration)
      windowFillingProgress = Float(sampleIndex) / Float(WINDOW_WIDTH)
    }
  }
  
  public func addManualEnterElevator() {
    if sampleIndex > WINDOW_WIDTH - 1 {
      manualEnterElevatorIndex = nil
      manualExitElevatorIndex = nil
      manualEnterElevatorIndex = sampleIndex - WINDOW_WIDTH
      print("entered elevator")
    }
  }
  
  public func addManualExitElevator() {
    if sampleIndex > WINDOW_WIDTH - 1 {
      manualExitElevatorIndex = sampleIndex - WINDOW_WIDTH
      print("exited elevator")
      
      // doesn't account for pings that are still in progress
      let totalLatency = latencyHistory[manualEnterElevatorIndex!...manualExitElevatorIndex!]
        .reduce(into: 0.0) {
          return $0 += $1.latency
        }
      let expectedLatency = Double(manualExitElevatorIndex! - manualEnterElevatorIndex!) * PING_INTERVAL
      let manualLatency = max(totalLatency, expectedLatency)
      
      
      errorString = "Hey, you took \(manualLatency) in the elevator. Floor estimate: \(ceil(manualLatency / 5.0))"
      print(errorString)
    }
  }
}
