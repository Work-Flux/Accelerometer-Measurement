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
 */

// Struct for displaying charts
struct chartView: View {
    // The stored data
    var displayedData: [recordedData]
    
    // The settings data
    var currentSettings: [String : Double]
    
    // What is the contents of the table
    @Binding var tableContents: [tableText]
    
    // What names do the data entries have and where are they displayed
    let dataEntries: [String]
    let dataEntryCount: [Int]
    @Binding var chartDisplays: [Bool]
    
    var body: some View {
        VStack {
            if chartDisplays[0] {  // Display basic accelerometer data chart
                baseAccelChartView(
                    displayedData: displayedData,
                    currentSettings: currentSettings
                )
            }
            
            if chartDisplays[1] {  // Display ∆M chart
                magnitudeChartView(
                    displayedData: displayedData,
                    currentSettings: currentSettings
                )
            }
            
            if chartDisplays[2] { // Display Equation: Energy chart
                powerChartView(
                    displayedData: displayedData,
                    currentSettings: currentSettings
                )
            }
            
            if chartDisplays[3] { // Display Equation: Current chart
                
            }
            
            if chartDisplays[4] { // Display Equation: Voltage chart
                
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
                    y: .value("Total Count", data.x)
                )
                .foregroundStyle(by: .value("Index", "x"))
                .interpolationMethod(.cardinal)
                .opacity(0.8)
                
                LineMark(
                    x: .value("Time", data.t),
                    y: .value("Total Count", data.y)
                )
                .foregroundStyle(by: .value("Index", "y"))
                .interpolationMethod(.cardinal)
                .opacity(0.8)
                
                LineMark(
                    x: .value("Time", data.t),
                    y: .value("Total Count", data.z)
                )
                .foregroundStyle(by: .value("Index", "z"))
                .interpolationMethod(.cardinal)
                .opacity(0.8)
            }
        }
    }
}

// Displays the accelerometer magnitude and change in magnitude data
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
                    y: .value("Total Count", data.m)
                )
                .foregroundStyle(by: .value("Index", "m"))
                .interpolationMethod(.cardinal)
                
                LineMark(
                    x: .value("Time", data.t),
                    y: .value("Total Count", data.dm)
                )
                .foregroundStyle(by: .value("Index", "dm"))
                .interpolationMethod(.cardinal)
            }
        }
    }
}

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
                    y: .value("Total Count", data.p * (currentSettings["Mass"] ?? 1))
                )
                .foregroundStyle(by: .value("Index", "p"))
                .interpolationMethod(.cardinal)
                
                LineMark(
                    x: .value("Time", data.t),
                    y: .value("Total Count", data.ke * (currentSettings["Mass"] ?? 1))
                )
                .foregroundStyle(by: .value("Index", "ke"))
                .interpolationMethod(.cardinal)
            }
        }
    }
}
