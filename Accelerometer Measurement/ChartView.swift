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
    @Binding var tableDisplays: [Bool]
    
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
                if data.index == "X" || data.index == "Y" || data.index == "Z" {
                    LineMark(
                        x: .value("Time", data.time),
                        y: .value("Total Count", data.value)
                    )
                    .foregroundStyle(by: .value("Index", data.index))
                    .interpolationMethod(.cardinal)
                    .opacity(0.8)
                }
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
                if data.index == "M" || data.index == "∆M" {
                    LineMark(
                        x: .value("Time", data.time),
                        y: .value("Total Count", data.value)
                    )
                    .foregroundStyle(by: .value("Index", data.index))
                    .interpolationMethod(.cardinal)
                }
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
                if data.index == "P" ||  data.index == "KE" {
                    LineMark(
                        x: .value("Time", data.time),
                        y: .value("Total Count", data.value * (currentSettings["Mass"] ?? 1))
                    )
                    .foregroundStyle(by: .value("Index", data.index))
                    .interpolationMethod(.cardinal)
                }
            }
        }
    }
}
