//
//  ContentView.swift
//  Accelerometer Measurement
//
//  Created by Finn Luxton on 17/03/2025.
//

import SwiftUI
import CoreMotion
import Charts

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
 */

// Duration of current recording
var counter: Double = 0.0

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
    
    init(value: Double, index: String) {
        self.value = value
        self.index = index
        self.time = counter // TODO: check need / re-write to remove internal reference to global instead of requesting it at use; possibly remove init
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

// Stores settings data for equations and display
class settingsData: ObservableObject {
    @Published var currentSettings: [String: Double] = [
        // Display settings
        // TODO: Make display settings
        // Equation settings
        "Mass" : 0.15, // Mass in kilograms
        "Resistance" : 1, // Electrical resistance in ohms
        "KE_0" : 0 // Starting Kinetic Energy in joules
    ]
    
}


/*
 Section for settings page, main page display, and functions for recording and processing the data
 
 Contains:
    Structs:
        Settings pop-up
        ContentView
    Functions:
        Starting and stopping recording, while processing the data from the accelerometers and adding it to the storage
 
 TODO: Add email exporting functionality
    Possibly integrate into endRecording or settings page
 TODO: Check viability of having recording function in the ContentView body
 */

// Settings pop-up page
struct settings: View {
    @Binding var popup: Bool
    
    var body: some View {
        Text("Settings")
        Text("Mass (g)") // Mass displayed in grams, converted to kg
        Text("Resistance (Ω)") // Resistance displayed in ohms
        Text("Starting Kinetic Energy (J)") // Assumed starting kinetic energy displayed in joules
    }
}

// Main page view
struct ContentView: View {
    let motionManager = CMMotionManager()
    
    // Real-time repositry for data to be displayed on the charts
    @StateObject var stored = storedData()
    
    // Real-time storage for settings data
    @StateObject var settings = settingsData()
    
    // Recording accelerometer Data
    @State private var accelerometerData: (x: Double, y: Double, z: Double) = (-1, 1, 0)
    @State private var xData: (recordedData) = recordedData(value: 0, index: "X")
    @State private var yData: (recordedData) = recordedData(value: 0, index: "Y")
    @State private var zData: (recordedData) = recordedData(value: 0, index: "Z")
    @State private var bulkAccelData: [Double] = [0, 0, 0]
    
    // Storing magnitudes from accelerometer
    @State private var mData: (recordedData) = recordedData(value: 0, index: "M")
    @State private var oldMData: Double = 0
    
    // Change in magnitude across single steps
    @State private var dmData: (recordedData) = recordedData(value: 0, index: "∆M")
    
    // Kinetic energy and Power across the recording time
    @State private var keData: (recordedData) = recordedData(value: 0, index: "KE")
    @State private var pData: (recordedData) = recordedData(value: 0, index: "P")
    
    // Timers for steps
    @State private var countTimer: Timer?
    @State private var accelTimer: Timer?
    
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
                    Accelerometer_Measurement.settings(popup: $popup)
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
            charts(
                displayedData: stored.displayData,
                currentSettings: settings.currentSettings,
                tableContents: $tableContents,
                dataEntries: ContentView.dataEntries,
                dataEntryCount: ContentView.dataEntryCount,
                chartDisplays: $chartDisplays,
                tableDisplays: $tableDisplays
            )
            
            // Add the tables to use the real-time data
            tables(
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
     TODO: Add computing of other values for variant tables
     */
    func startRecording() {
        // Clear previous values
        tableContents.removeAll()
        stored.displayData.removeAll()
        counter = 0.0
        
        // Set starting kinetic energy to designated settings value
        var kineticEnergy = settings.currentSettings["KE_0"] ?? 0
        
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
                    self.xData = recordedData(value: bulkAccelData[0], index: "X")
                    stored.addToDisplay(xData)
                    
                    self.yData = recordedData(value: bulkAccelData[1], index: "Y")
                    stored.addToDisplay(yData)
                    
                    self.zData = recordedData(value: bulkAccelData[2], index: "Z")
                    stored.addToDisplay(zData)
                    
                    // Find magnitude from raw accelerometer data
                    self.mData = recordedData(value: abs(sqrt(bulkAccelData.reduce(0) {$0 + pow($1, 2)}) - 1), index: "M")
                    stored.addToDisplay(mData)
                    
                    // Find change in magnitude between steps
                    self.dmData = recordedData(value: self.mData.value - self.oldMData, index: "∆M")
                    stored.addToDisplay(dmData)
                    
                    self.oldMData = self.mData.value
                    
                    self.pData = recordedData(value: 1 / 2 * pow(self.dmData.value * stepTime, 2) * stepTime, index: "P")
                    stored.addToDisplay(pData)
                    
                    kineticEnergy += (self.pData.value / stepTime) * (self.dmData.value > 0 ? 1 : -1)
                    self.keData = recordedData(value: kineticEnergy, index: "KE")
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


/*
 Section for displaying a series of charts to convey details about the acceleration of the device and implications of said acceleration
 
 Contains:
    Struct grouping charts and displaying them based on selection
    Structs for the generation of charts according to settings
 
 TODO: Make charts tappable to pop up expanded and scrollable view of the selected one
 */

// Struct for displaying charts
struct charts: View {
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
                baseAccelChart(
                    displayedData: displayedData,
                    currentSettings: currentSettings
                )
            }
            
            if chartDisplays[1] {  // Display ∆M chart
                magnitudeChart(
                    displayedData: displayedData,
                    currentSettings: currentSettings
                )
            }
            
            if chartDisplays[2] { // Display Equation: Energy chart
                powerChart(
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
struct baseAccelChart: View {
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
struct magnitudeChart: View {
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

struct powerChart: View {
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

/*
 Section for creating a table after ending recording of accelerometer data for manual comparison and checking what would be exported as csv via email
 
 Contains:
    Main struct for displaying tables
    Data storage struct for contents and order of data sent to tables
 
 TODO: Check modification of power data based on changing settings
    Might need re-generation from endRecording
    Possibly seperate out chart generation into new function
 */

// Struct for displaying tables
struct tables: View {
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
        // Table display
        let tableSet = zip(tableDisplays, dataEntryCount)
        let tableCount: Int = tableSet.map{($0 ? 1 : 0) * $1}.reduce(0, +)
        let columns: [GridItem] = Array(repeating: GridItem(.flexible()), count: addedValueCount + tableCount)
        ScrollView{
            LazyVGrid(columns: columns) {
                Text("Time")
                if tableDisplays[0] {
                    Text("X")
                    Text("Y")
                    Text("Z")
                }
                
                if tableDisplays[1] {
                    Text("M")
                    Text("∆M")
                }
                
                if tableDisplays[2] {
                    Text("P")
                    Text("KE")
                }
                
                if tableDisplays[3] {
                    
                }
                
                if tableDisplays[4] {
                    
                }
                
                ForEach(tableContents) { data in
                    Text(data.T)
                    if tableDisplays[0] {
                        Text(data.X)
                        Text(data.Y)
                        Text(data.Z)
                    }
                    
                    if tableDisplays[1] {
                        Text(data.M)
                        Text(data.dM)
                    }
                    
                    if tableDisplays[2] { //TODO: Cause of inaccuracy from stopRecording log
                        Text(String(format: "%.5f", (Double(data.P) ?? 0) * (currentSettings["Mass"] ?? 1)))
                        Text(String(format: "%.5f", (Double(data.KE) ?? 0) * (currentSettings["Mass"] ?? 1)))
                    }
                    
                    if tableDisplays[3] {
                        
                    }
                    
                    if tableDisplays[4] {
                        
                    }
                }
            }
        }
    }
}

// Struct storing data for all potential table columns at a single time
struct tableText: Identifiable {
    let T: String // Time
    let X: String // XYZ acceleration
    let Y: String
    let Z: String
    let M: String // Magnitude of acceleration
    let dM: String // Change in magnitude between steps
    let P: String // Specific power from movement
    let KE: String // Specific kinetic energy from change between steps
    let id = UUID()
    
    init(inputValues: [String]) {self.T = inputValues[0]
        self.X = inputValues[1]
        self.Y = inputValues[2]
        self.Z = inputValues[3]
        self.M = inputValues[4]
        self.dM = inputValues[5]
        self.P = inputValues[6]
        self.KE = inputValues[7]
    }
}

#Preview {
    ContentView()
}
