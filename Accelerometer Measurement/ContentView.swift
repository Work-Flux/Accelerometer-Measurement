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
 TODO: Make starting settingsData values the default values used in settingsView
 TODO: Check KE stepping away from zero on movement
 */

// Tick rate for timers / accelerometer updates
let stepTime: Double = 0.1

// How many non-dependant variables exist that are used in displays
let addedValueCount: Int = 1

// How many dependant variables exist that are used in displays
let recordedValueCount: Int = 7

// Stores accelerometer data each tick and calculates additional values from it
struct recordedData: Identifiable {
    let valueRange: [Double] // Range of values recorded each tick
    
    let t: Double // When it is
    let x: Double // Acceleration in xyz axes
    let y: Double
    let z: Double
    
    // Calculated values from recorded data in valueRange
    let m: Double // Magnitude of acceleration
    let dm: Double // Change in magnitude of acceleration
    let p: Double // Power from changing acceleration
    let ke: Double // Total kinetic energy
    let id = UUID()
    
    init(valueRange: [Double], pastM: Double, pastKE: Double) {
        self.valueRange = valueRange
        self.t = valueRange[0]
        self.x = valueRange[1]
        self.y = valueRange[2]
        self.z = valueRange[3]
        self.m = abs(sqrt(valueRange[1...3].reduce(0) {$0 + pow($1, 2)}) - 1)
        self.dm = self.m - pastM
        self.p = 1 / 2 * pow(self.dm * stepTime, 2) * stepTime
        self.ke = pastKE + (self.p / stepTime) * (self.dm > 0 ? 1 : -1)
    }
}

// Stores all data which can be displayed
class storedData: ObservableObject {
    @Published var displayData: [recordedData] = []
    
    func addToDisplayData(_ data: recordedData) {
        DispatchQueue.main.async {
            self.displayData.append(data)
        }
    }
}


// Stores settings data for equations and display and sets default values
class settingsData: ObservableObject {
    @Published var currentSettings: [String: Double] = [:]
    
    let defaultSettings: [String: Double] = [
        "Mass" : 1, 
        "V0" : 0,
        "Resistance" : 1
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
    @State private var accelerometerData: (x: Double, y: Double, z: Double) = (0, 0, -1)
    @State private var bulkAccelData: [Double] = [0, 0, -1]
    
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
                    settingView(currentSettings: $settings.currentSettings, defaultSettings: settings.defaultSettings, popup: $popup)
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
                chartDisplays: $chartDisplays
            )
            
            // Add the tables to use the real-time data
            tableView(
                currentSettings: settings.currentSettings,
                tableContents: $tableContents,
                dataEntries: ContentView.dataEntries,
                dataEntryCount: ContentView.dataEntryCount,
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
                    bulkAccelData = [
                        counter,
                        accelerometerData.acceleration.x,
                        accelerometerData.acceleration.y,
                        accelerometerData.acceleration.z
                    ]
                    
                    let pastData = stored.displayData.last ?? recordedData(valueRange: [0, 0, 0, -1], pastM: 0, pastKE: 0)
                    
                    stored.addToDisplayData(recordedData(valueRange: bulkAccelData, pastM: pastData.m, pastKE: pastData.ke))
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
            let timeString = String(format: "%.1f", stored.displayData[i].t)
            
            // Adding and formatting dependant variables
            let xString = String(format: "%.3f", stored.displayData[i].x)
            let yString = String(format: "%.3f", stored.displayData[i].y)
            let zString = String(format: "%.3f", stored.displayData[i].z)
            let mString = String(format: "%.3f", stored.displayData[i].m)
            let dmString = String(format: "%.3f", stored.displayData[i].dm)
            let pString = String(format: "%.3f", stored.displayData[i].p * 1000) + "e-3"
            let keString = String(format: "%.3f", stored.displayData[i].ke * 1000) + "e-3"
            
            // Saving row
            let segment: [String] = [timeString, xString, yString, zString, mString, dmString, pString, keString]
            
            csvText += segment.joined(separator: ",") + "\n"
            
            tableContents.append(tableText(inputValues: segment))
        }
    }
}


#Preview {
    ContentView()
}
