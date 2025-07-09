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
    Also appears to disrupt the interpolation
        Possible multiple entries stacking?
    When stopped it continues subtracting points until only one is left
    Eventually fixes itself
        Maybe errors in buffer?
 FIXME: Updates to charts are not smooth resulting in visable steps at each tick
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
    private var dataRange: Int { Int((currentSettings["ChartLength"] ?? 10) / (currentSettings["tickRate"] ?? 0.1)) }
    private var data: [recordedData] { Array(displayedData.suffix(dataRange)) }
    
    
    var body: some View {
        VStack {
            if chartDisplays[0] {  // Display basic accelerometer data chart
                lineChart(
                    displayedData: data,
                    vKeys: [[\.aX , \.aY, \.aZ]],
                    names: [["X", "Y", "Z"]],
                    opaque: [true],
                    title: "Acceleration (m/s2)"
                )
            }
            
            if chartDisplays[1] {  // Display velocity chart
                lineChart(
                    displayedData: data,
                    vKeys: [[\.vX , \.vY, \.vZ]],
                    names: [["X", "Y", "Z"]],
                    opaque: [true],
                    title: "Velocity (m/s)"
                )
            }
            
            if chartDisplays[2] { // Display power
                lineChart(
                    displayedData: data,
                    vKeys: [[\.pX , \.pY, \.pZ]],
                    names: [["X", "Y", "Z"]],
                    opaque: [true],
                    title: "Power (W)"
                )
            }
            
            if chartDisplays[3] { // Display magnitude
                lineChart(
                    displayedData: data,
                    vKeys: [[\.aM , \.adM], [\.pM, \.pdM]],
                    names: [["Acceleration Magnitude", "Change in A.Magnitude"], ["Power Magnitude", "Change in P.Magnitude"]],
                    title: "Magnitudes (m/s2, W)"
                )
            }
            
            if chartDisplays[4] { // Display circuit values
                lineChart(
                    displayedData: data,
                    vKeys: [[\.i , \.v]],
                    names: [["Current", "Voltage"]],
                    title: "Current and Voltage (A, V)"
                )
            }
        }
    }
}

// Generic struct for making charts
struct lineChart: View {
    // The stored data
    var displayedData: [recordedData]
    // ids for pulling from stored data
    let vKeys: [[KeyPath<recordedData, Double>]]
    // Names for chart legend for each variable key
    let names: [[String]]
    // Whether or not to partially fade the linemarks
    let opaque: [Bool]
    // What to title the chart
    let title: String
    
    init(
        displayedData: [recordedData],
        vKeys: [[KeyPath<recordedData, Double>]],
        names: [[String]],
        opaque: [Bool] = [false],
        title: String
    ) {
        self.displayedData = displayedData
        self.vKeys = vKeys
        self.names = names
        self.opaque = opaque
        self.title = title
    }
    
    var body: some View {
        GroupBox(title) {
            ForEach(Array(names.enumerated()), id: \.offset) { index, _ in
                Chart {
                    lines(
                        displayedData: displayedData,
                        vKeys: vKeys[index],
                        names: names[index],
                        opaque: opaque == [false] ? false : opaque[index]
                    )
                }
                .chartXScale(domain: (displayedData.first?.t ?? 0) ... (displayedData.last?.t ?? 1))
            }
        }
    }
}


struct lines: ChartContent {
    // The stored data
    var displayedData: [recordedData]
    // ids for pulling from stored data
    let vKeys: [KeyPath<recordedData, Double>]
    // Names for chart legend for each variable key
    let names: [String]
    // Whether or not to partially fade the linemarks
    let opaque: Bool
    
    var body: some ChartContent {
        ForEach(displayedData) { data in
            ForEach(Array(vKeys.enumerated()), id: \.offset) { index, vKey in
                LineMark(
                    x: .value("Time", data.t),
                    y: .value("Total Count", data[keyPath: vKey])
                )
                .foregroundStyle(by: .value("Index", names[index]))
                .interpolationMethod(.cardinal)
                .opacity(opaque ? 1 : 0.8)
            }
        }
    }
}
