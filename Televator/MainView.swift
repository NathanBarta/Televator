//
//  MainView.swift
//  Televator
//
//  Created by Nathan Barta on 2/19/24.
//

import SwiftUI
import Charts

struct MainView: View {
  @StateObject var viewModel = MainViewViewModel()
    
  var body: some View {
    VStack(spacing: 16.0) {
      //      gps
      //      accelerometer
      //      magnet
      //      gravity
      //      barometric
      
      chart

      Text(viewModel.errorString)
        .background(.red)
    }
    .padding()
  }
  
  var gps: some View {
    VStack {
      Text("GPS Radius of Uncertainty")
      Text(viewModel.gpsSignalStrength.description)
      Text(viewModel.gpsTimeSinceLastUpdate.description)
    }
  }
  
  var accelerometer: some View {
    VStack {
      Text("(Z-axis) Accelerometer")
      Text(String(format: "%.3f", viewModel.zAcceleration))
    }
  }
  
  var magnet: some View {
    VStack {
      Text("Magnetometer")
      Text(String(format: "%.3f", viewModel.mMagnetometer))
    }
  }
  
  var gravity: some View {
    VStack {
      Text("Gravity")
      Text(String(format: "%.3f", viewModel.zGravity))
    }
  }
  
  var barometric: some View {
    VStack {
      Text("Barometric Pressure")
      Text(String(format: "%.3f", viewModel.barometric))
    }
  }
  
  var chart: some View {
    Chart {
      RuleMark(y: .value("Limit", 0.5))
        .foregroundStyle(.green)
      
      ForEach(Array(viewModel.latencyHistory.enumerated()), id: \.offset) { index, value in
        LineMark(
          x: .value("Sample", index),
          y: .value("Latency", value)
        )
        
        // Pretty intensive
        //        AreaMark(
        //          x: .value("Sample", index),
        //          y: .value("Latency", value)
        //        )
        //        .foregroundStyle(.blue.opacity(0.8))
      }
    }
  }
}

#Preview {
  MainView()
}
