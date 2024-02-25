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
let WINDOW_WIDTH: Int = 10

public struct LatencyRecord: Identifiable {
  public let id: Int
  public let latency: TimeInterval
}

final public class MainViewViewModel: NSObject, ObservableObject {
  @Published var latencyHistory: [LatencyRecord] = .init()
  @Published var rollingAvg: TimeInterval? = nil
  @Published var manualEnterElevatorIndex: Int?
  @Published var manualExitElevatorIndex: Int?
  
  private var windowSum: TimeInterval = .zero
  private var rollingSum: TimeInterval = .zero
  private var sampleIndex: Int = -1
  
  @Published var errorString: String = .init()

  override init() {
    super.init()

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
    latencyHistory.append(.init(id: Int(sequenceNumber), latency: duration))
    #if DEBUG
      print(sequenceNumber, duration)
    #endif
    
    rollingSum += duration
    if sequenceNumber > WINDOW_WIDTH {
      rollingSum -= latencyHistory[Int(sequenceNumber) - WINDOW_WIDTH].latency
      rollingAvg = rollingSum / Double(WINDOW_WIDTH)
    }
  }
  
  public func addManualEnterElevator() {
    manualEnterElevatorIndex = sampleIndex
  }
  
  public func addManualExitElevator() {
    manualExitElevatorIndex = sampleIndex
  }
}
