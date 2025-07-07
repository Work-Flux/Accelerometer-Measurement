//
//  ChartView.swift
//  Accelerometer Measurement
//
//  Created by Finn Luxton on 24/06/2025.
//

import SwiftUI
import Charts

/*
 Section for displaying a series of charts to convey details about the acceleration of the device and implications of said acceleration
 
 Contains:
    Struct grouping charts and displaying them based on selection
    Structs for the generation of charts according to settings
 
 TODO: Make charts tappable to pop up expanded and scrollable view of the selected one
    Possible resolution to issue of chart viwability at high durations of data collection
 TODO: Possible re-write to only trigger chart update on tick to add latest
 TODO: Figure out way to have lineMarks as structs / similar to reduce copied code for each chart
 
 FIXME: When tables are open it disrupts the limited domain range display + when device is turned off->on
    Also appears to disrupt the interpoolation
    When stopped it continues subtracting points until only one is left
    Eventually fixes itself
        Maybe errors in buffer?
 */

// Struct for displaying charts
struct chartView: View {
    // The passed external data that is displayed
    var displayedData: [recordedData]
    
    // The settings data
    var currentSettings: [String : Double]
    
    // What charts are active
    @Binding var chartDisplays: [Bool]
    
    // Limits the amount of rendered data to the number of seconds selected in settings
    private var dataRange: Int { Int((currentSettings["ChartLength"] ?? 10) / (currentSettings["StepTime"] ?? 0.1)) }
    private var data: [recordedData] { Array(displayedData.suffix(dataRange)) }
    
    
    var body: some View {
        VStack {
            if chartDisplays[0] {  // Display basic accelerometer data chart
                baseAccelChartView(displayedData: data)
            }
            
            if chartDisplays[1] {  // Display velocity chart
                velocityChartView(displayedData: data)
            }
            
            if chartDisplays[2] { // Display power
                powerChartView(displayedData: data)
            }
            
            if chartDisplays[3] { // Display magnitude
                magnitudeChartView(displayedData: data)
            }
            
            if chartDisplays[4] { // Display circuit values
                circuitChartView(displayedData: data)
            }
        }
    }
}


// Displays the baseline xyz accelerometer data
struct baseAccelChartView: View {
    // The stored data
    var displayedData: [recordedData]
    
    var body: some View {
        GroupBox("Acceleration (m/s2)") {
            Chart {
                ForEach(displayedData) { data in
                    LineMark(
                        x: .value("Time", data.t),
                        y: .value("Total Count", data.aX)
                    )
                    .foregroundStyle(by: .value("Index", "X"))
                    .interpolationMethod(.cardinal)
                    .opacity(0.8)
                    
                    LineMark(
                        x: .value("Time", data.t),
                        y: .value("Total Count", data.aY)
                    )
                    .foregroundStyle(by: .value("Index", "Y"))
                    .interpolationMethod(.cardinal)
                    .opacity(0.8)
                    
                    LineMark(
                        x: .value("Time", data.t),
                        y: .value("Total Count", data.aZ)
                    )
                    .foregroundStyle(by: .value("Index", "Z"))
                    .interpolationMethod(.cardinal)
                    .opacity(0.8)
                }
            }
            .chartXScale(domain: ((displayedData.first?.t ?? 0) ... (displayedData.last?.t ?? 1)))
        }
    }
}

// Displays the calculated xyz velocity data
struct velocityChartView: View {
    // The stored data
    var displayedData: [recordedData]
    
    var body: some View {
        GroupBox("Velocity (m/s)") {
            Chart {
                ForEach(displayedData) { data in
                    LineMark(
                        x: .value("Time", data.t),
                        y: .value("Total Count", data.vX)
                    )
                    .foregroundStyle(by: .value("Index", "X"))
                    .interpolationMethod(.cardinal)
                    .opacity(0.8)
                    
                    LineMark(
                        x: .value("Time", data.t),
                        y: .value("Total Count", data.vY)
                    )
                    .foregroundStyle(by: .value("Index", "Y"))
                    .interpolationMethod(.cardinal)
                    .opacity(0.8)
                    
                    LineMark(
                        x: .value("Time", data.t),
                        y: .value("Total Count", data.vZ)
                    )
                    .foregroundStyle(by: .value("Index", "Z"))
                    .interpolationMethod(.cardinal)
                    .opacity(0.8)
                }
            }
            .chartXScale(domain: (displayedData.first?.t ?? 0) ... (displayedData.last?.t ?? 1))
        }
    }
}

// Displays the calculated xyz power data
struct powerChartView: View {
    // The stored data
    var displayedData: [recordedData]
    
    var body: some View {
        GroupBox("Power (W)") {
            Chart {
                ForEach(displayedData) { data in
                    LineMark(
                        x: .value("Time", data.t),
                        y: .value("Total Count", data.pX)
                    )
                    .foregroundStyle(by: .value("Index", "X"))
                    .interpolationMethod(.cardinal)
                    .opacity(0.8)
                    
                    LineMark(
                        x: .value("Time", data.t),
                        y: .value("Total Count", data.pY)
                    )
                    .foregroundStyle(by: .value("Index", "Y"))
                    .interpolationMethod(.cardinal)
                    .opacity(0.8)
                    
                    LineMark(
                        x: .value("Time", data.t),
                        y: .value("Total Count", data.pZ)
                    )
                    .foregroundStyle(by: .value("Index", "Z"))
                    .interpolationMethod(.cardinal)
                    .opacity(0.8)
                }
            }
            .chartXScale(domain: (displayedData.first?.t ?? 0) ... (displayedData.last?.t ?? 1))
        }
    }
}

// Displays the accelerometer and power magnitude and the change in them
struct magnitudeChartView: View {
    // The stored data
    var displayedData: [recordedData]
    
    var body: some View {
        GroupBox("Magnitudes (m/s2, W)") {
            HStack {
                Chart {
                    ForEach(displayedData) { data in
                        LineMark(
                            x: .value("Time", data.t),
                            y: .value("Total Count", data.aM)
                        )
                        .foregroundStyle(by: .value("Index", "Acceleration Magnitude"))
                        .interpolationMethod(.cardinal)
                        .opacity(0.8)
                        
                        LineMark(
                            x: .value("Time", data.t),
                            y: .value("Total Count", data.adM)
                        )
                        .foregroundStyle(by: .value("Index", "Change in A.Magnitude"))
                        .interpolationMethod(.cardinal)
                        .opacity(0.8)
                    }
                }
                .chartXScale(domain: (displayedData.first?.t ?? 0) ... (displayedData.last?.t ?? 1))
                Chart {
                    ForEach(displayedData) { data in
                        LineMark(
                            x: .value("Time", data.t),
                            y: .value("Total Count", data.pM)
                        )
                        .foregroundStyle(by: .value("Index", "Power Magnitude"))
                        .interpolationMethod(.cardinal)
                        .opacity(0.8)
                        
                        LineMark(
                            x: .value("Time", data.t),
                            y: .value("Total Count", data.pdM)
                        )
                        .foregroundStyle(by: .value("Index", "Change in P.Magnitude"))
                        .interpolationMethod(.cardinal)
                        .opacity(0.8)
                    }
                }
                .chartXScale(domain: (displayedData.first?.t ?? 0) ... (displayedData.last?.t ?? 1))
            }
        }
    }
}

// Displays the calculated voltage and current
struct circuitChartView: View {
    // The stored data
    var displayedData: [recordedData]
    
    var body: some View {
        GroupBox("Current and Voltage (A, V)") {
            Chart {
                ForEach(displayedData) { data in
                    LineMark(
                        x: .value("Time", data.t),
                        y: .value("Total Count", data.i)
                    )
                    .foregroundStyle(by: .value("Index", "Current"))
                    .interpolationMethod(.cardinal)
                    
                    LineMark(
                        x: .value("Time", data.t),
                        y: .value("Total Count", data.v)
                    )
                    .foregroundStyle(by: .value("Index", "Voltage"))
                    .interpolationMethod(.cardinal)
                }
            }
            .chartXScale(domain: (displayedData.first?.t ?? 0) ... (displayedData.last?.t ?? 1))
        }
    }
}
