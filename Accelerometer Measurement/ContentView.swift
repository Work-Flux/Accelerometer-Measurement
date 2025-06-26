//
//  ContentView.swift
//  Accelerometer Measurement
//
//  Created by Finn Luxton on 17/03/2025.
//

import SwiftUI
import CoreMotion

/*
 Section for setting initial variables, establishing data structs, and establishing classes for the real-time storage and use of information
 
 Contains:
    Variables:
        Current duration
        Tick rate of timers
        Count of dependant and non-dependant recorded display variables
    Struct:
        Identifiable record of a value at a time and what said value represents
    Classes:
        Real-time record of data from accelerometer and calculated from it
        Real-time settings data which impacts visuals and equations
 
 TODO: Re-write recordedData to take an array and internally seperate it out
 TODO: Check need for counter as global, if so re-write recordedData to remove reference
 TODO: Make starting settingsData values the default values used in settingsView
 */

// Tick rate for timers / accelerometer updates
let stepTime: Double = 0.1

// How many non-dependant variables exist that are used in displays
let addedValueCount: Int = 1

// How many dependant variables exist that are used in displays
let recordedValueCount: Int = 7

// Stores accelerometer data based on their time, value, and index
struct recordedData: Identifiable {
    let value: Double // Magnitude
    let index: String // What it is
    let time: Double // When it is
    let id = UUID()
    
    init(value: Double, index: String, time: Double) {
        self.value = value
        self.index = index
        self.time = time
    }
}

// Stores all data which can be displayed
class storedData: ObservableObject {
    @Published var displayData: [recordedData] = []
    
    func addToDisplay(_ data: recordedData) {
        DispatchQueue.main.async {
            self.displayData.append(data)
        }
    }
}


// Stores settings data for equations and display and sets default values
class settingsData: ObservableObject {
    @Published var currentSettings: [String: Double] = [
        // Display settings
        
        // Equation settings
        "Mass" : 1, // Mass in kilograms
        "Resistance" : 1, // Electrical resistance in ohms
        "V0" : 0 // Starting velocity in m/s
    ]
    
}

/*
 Section for main page display, and functions for recording and processing the data
 
 Contains:
    Structs:
        ContentView
    Functions:
        Starting and stopping recording, while processing the data from the accelerometers and adding it to the storage
 
 TODO: Add email exporting functionality
    Possibly integrate into endRecording or settings page
 TODO: Check viability of having recording function in the ContentView body
 TODO: Add computing of other values for variant tables
 */

// Main page view
struct ContentView: View {
    let motionManager = CMMotionManager()
    
    // Real-time repositry for data to be displayed on the charts
    @StateObject var stored = storedData()
    
    // Real-time storage for settings data
    @StateObject var settings = settingsData()
    
    // Recording accelerometer Data
    @State private var accelerometerData: (x: Double, y: Double, z: Double) = (-1, 1, 0)
    @State private var xData: (recordedData) = recordedData(value: 0, index: "X", time: 0)
    @State private var yData: (recordedData) = recordedData(value: 0, index: "Y", time: 0)
    @State private var zData: (recordedData) = recordedData(value: 0, index: "Z", time: 0)
    @State private var bulkAccelData: [Double] = [0, 0, 0]
    
    // Storing magnitudes from accelerometer
    @State private var mData: (recordedData) = recordedData(value: 0, index: "M", time: 0)
    @State private var oldMData: Double = 0
    
    // Change in magnitude across single steps
    @State private var dmData: (recordedData) = recordedData(value: 0, index: "∆M", time: 0)
    
    // Kinetic energy and Power across the recording time
    @State private var keData: (recordedData) = recordedData(value: 0, index: "KE", time: 0)
    @State private var pData: (recordedData) = recordedData(value: 0, index: "P", time: 0)
    
    // Timers for steps
    @State private var countTimer: Timer?
    @State private var accelTimer: Timer?
    
    // Duration of current recording
    @State private var counter: Double = 0.0
    
    // If we are recording the accelerometer data
    @State private var recording: Bool = false
    
    // If we are displaying the settings popup
    @State private var popup: Bool = false
    
    // The update variable
    @State private var dRand: Double = 0.0
    
    // Table and export variables
    @State private var csvText: String = ""
    
    var startingSegment: [String] = Array()
    @State private var tableContents: [tableText] = [tableText(inputValues: Array(repeating: "0", count: addedValueCount + recordedValueCount))]
    
    // What names do the data entries have and how many are displayed per title
    static private let dataEntries: [String] = ["Acclerometer Data (ms2)", "Change in Magnitude", "Energy (J)", "Current (A)", "Voltage (V)"]
    static private let dataEntryCount: [Int] = [3, 2, 2, 0, 0]
    
    // What charts and tables are currently active
    @State private var chartDisplays: [Bool] = [true, true] + Array(repeating: false, count: dataEntries.count - 2)
    @State private var tableDisplays: [Bool] = [true, true] + Array(repeating: false, count: dataEntries.count - 2)
    
    var body: some View {
        VStack {
            Text("Accelerometer Data").font(.largeTitle)
            Text("Duration: \(String(format: "%.1f", counter))s - Update: \(String(format: "%.2f", dRand))")
            HStack {
                Button("Settings and Infromation", systemImage: "gearshape.fill") {
                    popup = true
                }
                .labelStyle(.iconOnly)
                .popover(isPresented: $popup) {
                    settingView(currentSettings: $settings.currentSettings, popup: $popup)
                }
                // For changing displayed charts; only allow two to be displayed at once
                Menu("Charts") {
                    ForEach(0..<ContentView.dataEntries.count, id: \.self) { i in
                        Toggle(ContentView.dataEntries[i], isOn: $chartDisplays[i]).disabled(2 == chartDisplays.filter { $0 }.count && !chartDisplays[i])
                    }
                }
                .menuActionDismissBehavior(.disabled)
                .buttonStyle(.bordered)
                
                // For changing what entries are displayed on the table
                Menu("Tables") {
                    ForEach(0..<ContentView.dataEntries.count, id: \.self) { i in
                        Toggle(ContentView.dataEntries[i], isOn: $tableDisplays[i])
                    }
                }
                .menuActionDismissBehavior(.disabled)
                .buttonStyle(.bordered)
                
                // Turns on / off the accelerometer recording, and exports results
                switch recording {
                case false:
                    Button("Start Recording", systemImage: "play.circle.fill") {
                        startRecording()
                        dRand = Double.random(in: 0.00...1.00)
                        recording.toggle()
                    }
                    .labelStyle(.iconOnly)
                case true:
                    Button("End Recording", systemImage: "stop.circle.fill") {
                        stopRecording()
                        recording.toggle()
                    }
                    .labelStyle(.iconOnly)
                }
            }
            
            // Add the charts to use the real-time data
            chartView(
                displayedData: stored.displayData,
                currentSettings: settings.currentSettings,
                tableContents: $tableContents,
                dataEntries: ContentView.dataEntries,
                dataEntryCount: ContentView.dataEntryCount,
                chartDisplays: $chartDisplays,
                tableDisplays: $tableDisplays
            )
            
            // Add the tables to use the real-time data
            tableView(
                currentSettings: settings.currentSettings,
                tableContents: $tableContents,
                dataEntries: ContentView.dataEntries,
                dataEntryCount: ContentView.dataEntryCount,
                chartDisplays: $chartDisplays,
                tableDisplays: $tableDisplays
            )
        }
        .padding()
    }
    
    /*
     Records data from the built-in accelerometer
     Computes magnitude and change in magnitude
     */
    func startRecording() {
        // Clear previous values
        tableContents.removeAll()
        stored.displayData.removeAll()
        counter = 0.0
        
        // Set starting kinetic energy to designated settings value
        var kineticEnergy = 1 / 2 * pow(settings.currentSettings["V0"] ?? 0, 2) * (settings.currentSettings["Mass"] ?? 1)
        
        // Start timer according to set values
        countTimer = Timer.scheduledTimer(withTimeInterval: stepTime, repeats: true) { timer in
            counter += stepTime
            dRand = Double.random(in: 0.00...1.00)
        }
        
        // Start recording accelerometer updates
        if motionManager.isAccelerometerAvailable {
            self.motionManager.accelerometerUpdateInterval = stepTime
            accelTimer = Timer.scheduledTimer(withTimeInterval: stepTime, repeats: true) { timer in
                motionManager.startAccelerometerUpdates(to: .main) {
                    (data, _) in guard let accelerometerData = data else { return }
                    bulkAccelData = [accelerometerData.acceleration.x, accelerometerData.acceleration.y, accelerometerData.acceleration.z]
                    
                    // Save raw accelerometer data
                    self.xData = recordedData(value: bulkAccelData[0], index: "X", time: counter)
                    stored.addToDisplay(xData)
                    
                    self.yData = recordedData(value: bulkAccelData[1], index: "Y", time: counter)
                    stored.addToDisplay(yData)
                    
                    self.zData = recordedData(value: bulkAccelData[2], index: "Z", time: counter)
                    stored.addToDisplay(zData)
                    
                    // Find magnitude from raw accelerometer data
                    self.mData = recordedData(value: abs(sqrt(bulkAccelData.reduce(0) {$0 + pow($1, 2)}) - 1), index: "M", time: counter)
                    stored.addToDisplay(mData)
                    
                    // Find change in magnitude between steps
                    self.dmData = recordedData(value: self.mData.value - self.oldMData, index: "∆M", time: counter)
                    stored.addToDisplay(dmData)
                    
                    self.oldMData = self.mData.value
                    
                    self.pData = recordedData(value: 1 / 2 * pow(self.dmData.value * stepTime, 2) * stepTime, index: "P", time: counter)
                    stored.addToDisplay(pData)
                    
                    kineticEnergy += (self.pData.value / stepTime) * (self.dmData.value > 0 ? 1 : -1)
                    self.keData = recordedData(value: kineticEnergy, index: "KE", time: counter)
                    stored.addToDisplay(keData)
                }
            }
        }
    }
    
    /*
     Stops timers and accelerometer recordings
     Tabulates data for display and exporting
     */
    func stopRecording() {
        // Stop updates and timers
        self.motionManager.stopAccelerometerUpdates()
        countTimer?.invalidate()
        countTimer = nil
        
        accelTimer?.invalidate()
        accelTimer = nil
        
        // Tablulate data
        // TODO: p/ke not going to .3 or adding e-3 (FOUND: In specific chart for values they are redefined)
        for (i, _) in stored.displayData.enumerated() {
            if i % recordedValueCount == 0 {
                let timeString = String(format: "%.1f", stored.displayData[i].time)
                
                // Adding and formatting dependant variables
                let xString = String(format: "%.3f", stored.displayData[i].value)
                let yString = String(format: "%.3f", stored.displayData[i + 1].value)
                let zString = String(format: "%.3f", stored.displayData[i + 2].value)
                let mString = String(format: "%.3f", stored.displayData[i + 3].value)
                let dmString = String(format: "%.3f", stored.displayData[i + 4].value)
                let pString = String(format: "%.3f", stored.displayData[i + 5].value * 1000) + "e-3"
                let keString = String(format: "%.3f", stored.displayData[i + 6].value * 1000) + "e-3"
                
                // Saving row
                let segment: [String] = [timeString, xString, yString, zString, mString, dmString, pString, keString]
                
                csvText += segment.joined(separator: ",") + "\n"
                
                tableContents.append(tableText(inputValues: segment))
            }
        }
    }
}


#Preview {
    ContentView()
}
