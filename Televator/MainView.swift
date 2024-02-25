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
  @State var isTapped = false
    
  var body: some View {
    VStack(spacing: 16.0) {
      chart

      Text(viewModel.errorString)
        .background(.red)
    }
    .padding()
  }

  var chart: some View {
    Chart {
      if let rollingAvg = viewModel.rollingAvg {
        RuleMark(y: .value("Rolling Avg", rollingAvg))
          .foregroundStyle(.green)
      }
      
      if let manualEnterElevatorIndex = viewModel.manualEnterElevatorIndex {
        RuleMark(
          x: .value("manualEnterElevatorTimesamp", manualEnterElevatorIndex),
          yStart: .value("manualEnterElevatorTimesamp", 0),
          yEnd: .value("manualEnterElevatorTimestamp", 0.5)
        )
        .foregroundStyle(.red)
      }
      
      if let manualExitElevatorIndex = viewModel.manualExitElevatorIndex {
        RuleMark(
          x: .value("manualEnterElevatorTimesamp", manualExitElevatorIndex),
          yStart: .value("manualEnterElevatorTimesamp", 0),
          yEnd: .value("manualEnterElevatorTimestamp", 0.5)
        )
        .foregroundStyle(.red)
      }
      
      ForEach(viewModel.latencyHistory, id: \.id) { record in
        LineMark(
          x: .value("Sample", record.id),
          y: .value("Latency", record.latency)
        )
      }
    }
    .simultaneousGesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in
          if !self.isTapped {
            self.isTapped = true
            self.viewModel.addManualEnterElevator()
          }
        }
        .onEnded { _ in
          self.isTapped = false
          self.viewModel.addManualExitElevator()
        }
    )
  }
}

#Preview {
  MainView()
}
