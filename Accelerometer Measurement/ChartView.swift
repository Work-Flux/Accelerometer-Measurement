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
 TODO: Possible re-write to only trigger chart update on tick to add latest, not write it all every time
 TODO: Add titles for charts
 */

// Struct for displaying charts
struct chartView: View {
    // The stored data
    var displayedData: [recordedData]
    
    // The settings data
    var currentSettings: [String : Double]
    
    // What is the contents of the table
    @Binding var tableContents: [tableText]
    
    // What charts are active
    @Binding var chartDisplays: [Bool]
    
    var body: some View {
        VStack {
            if chartDisplays[0] {  // Display basic accelerometer data chart
                baseAccelChartView(
                    displayedData: displayedData,
                    currentSettings: currentSettings
                )
            }
            
            if chartDisplays[1] {  // Display velocity chart
                velocityChartView(
                    displayedData: displayedData,
                    currentSettings: currentSettings
                )
            }
            
            if chartDisplays[2] { // Display power
                powerChartView(
                    displayedData: displayedData,
                    currentSettings: currentSettings
                )
            }
            
            if chartDisplays[3] { // Display magnitude
                magnitudeChartView(
                    displayedData: displayedData,
                    currentSettings: currentSettings)
            }
            
            if chartDisplays[4] { // Display circuit values
                circuitChartView(
                    displayedData: displayedData,
                    currentSettings: currentSettings)
            }
        }
    }
}


// Displays the baseline xyz accelerometer data
struct baseAccelChartView: View {
    // The stored data
    var displayedData: [recordedData]
    
    // The settings data
    var currentSettings: [String : Double]
    
    var body: some View {
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
    }
}

// Displays the calculated xyz velocity data
struct velocityChartView: View {
    // The stored data
    var displayedData: [recordedData]
    
    // The settings data
    var currentSettings: [String : Double]
    
    var body: some View {
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
    }
}

// Displays the calculated xyz power data
struct powerChartView: View {
    // The stored data
    var displayedData: [recordedData]
    
    // The settings data
    var currentSettings: [String : Double]
    
    var body: some View {
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
    }
}

// Displays the accelerometer and power magnitude and the change in them
struct magnitudeChartView: View {
    // The stored data
    var displayedData: [recordedData]
    
    // The settings data
    var currentSettings: [String : Double]
    
    var body: some View {
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
    }
}

// Displays the calculated voltage and current
struct circuitChartView: View {
    // The stored data
    var displayedData: [recordedData]
    
    // The settings data
    var currentSettings: [String : Double]
    
    var body: some View {
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
    }
}
