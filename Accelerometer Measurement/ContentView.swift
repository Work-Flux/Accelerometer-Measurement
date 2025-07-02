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
 
 TODO: Check velocity having negative trend on one axis
    Gravity not properly removed?
    Switched to deviceMotion user updates instead of raw accel but issue still present, readout seems less stable
 TODO: Crashes due to memory use when stopping recording after couple minutes
 TODO: Add catch for setting timestep to <=0
 */

// Tick rate for timers / accelerometer updates
let stepTime: Double = 0.1

// How many non-dependant variables exist that are used in displays
let addedValueCount: Int = 1

// How many dependant variables exist that are used in displays
let recordedValueCount: Int = 15

// Stores accelerometer data each tick and calculates additional values from it
struct recordedData: Identifiable {
    // Range of values recorded each tick
    let valueRange: [Double]
    // When it is
    let t: Double
    // Acceleration in xyz axes
    let aX: Double
    let aY: Double
    let aZ: Double
    
    // Velocity in xyz axes
    let vX: Double
    let vY: Double
    let vZ: Double
    
    // Magnitude of acceleration and change in said magnitude
    let aM: Double
    let adM: Double
    
    // Power from respective velocity changes
    let pX: Double
    let pY: Double
    let pZ: Double
    
    // Magnitude of power and change in said magnitude
    let pM: Double
    let pdM: Double
    
    // Current from power magnitude and set resistance
    let i: Double
    // Voltage from current
    let v: Double
    
    let id = UUID()
    
    init(valueRange: [Double], pastVelocity: [Double], pastMagnitudes: [Double], currentSettings: [String : Double]) {
        self.valueRange = valueRange
        self.t = valueRange[0]
        
        self.aX = valueRange[1]
        self.aY = valueRange[2]
        self.aZ = valueRange[3]
        
        self.aM = sqrt(valueRange[1...3].reduce(0) {$0 + pow($1, 2)})
        self.adM = self.aM - pastMagnitudes[0]
        
        switch valueRange[0] {
        case 0:
            self.vX = 0
            self.vY = currentSettings["V0"]!
            self.vZ = 0
        default:
            self.vX = pastVelocity[0] + self.aX
            self.vY = pastVelocity[1] + self.aY
            self.vZ = pastVelocity[2] + self.aZ
        }
        
        self.pX = aX * vX * currentSettings["Mass"]!
        self.pY = aY * vY * currentSettings["Mass"]!
        self.pZ = aZ * vZ * currentSettings["Mass"]!
        
        self.pM = sqrt(pow(self.pX, 2) + pow(self.pY, 2) + pow(self.pZ, 2))
        self.pdM = self.pM - pastMagnitudes[1]
        
        self.i = sqrt(self.pM * currentSettings["Resistance"]!)
        self.v = i * currentSettings["Resistance"]!
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
        "Mass" : 1, // Mass in kg
        "V0" : 0, // Starting velocity in m/s
        "Resistance" : 0.1, // Circuit resistance in Ω
        
        "StepTime" : 0.1, // Tick rate for timers / accelerometer updates
        
        "ChartLength" : 2, // Number of seconds of data to display
        "TableValueLength" : 3 // Number of values after the decimal to display"
    ]
    
    init() {
        self.currentSettings = defaultSettings
    }
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
 TODO: Meters per second
 TODO: Add initial "press start recording button for charts/tables"
 TODO: Check stopRecording spiking memory
    Assumed to be due to table writing, needs validation
 */

// Main page view
struct ContentView: View {
    let motionManager = CMMotionManager()
    
    // Real-time repositry for data to be displayed on the charts
    @StateObject var stored = storedData()
    
    // Real-time storage for settings data
    @StateObject var settings = settingsData()
    
    // Recording accelerometer Data
    @State private var accelerometerData: (x: Double, y: Double, z: Double) = (0, 0, 0)
    @State private var bulkAccelData: [Double] = [0, 0, 0]
    
    // Recording previous timestep's theoretical velocity for storedData calculations
    @State private var pastVelocity: [Double] = [0, 0, 0]
    // Recording previous timestep's magnitudes of acceleration and power
    @State private var pastMagnitudes: [Double] = [0, 0]
    
    // Timers for steps
    @State private var countTimer: Timer?
    @State private var accelTimer: Timer?
    
    // Duration of current recording
    @State private var counter: Double = 0.0
    
    // If we are recording the accelerometer data
    @State private var recording: Bool = false
    
    // If we are displaying the settings popup
    @State private var settingsPopup: Bool = false
    
    // If we are displaying the table popup
    @State private var tablePopup: Bool = false
    
    // The update variable
    @State private var dRand: Double = 0.0
    
    // Table and export variables
    @State private var csvText: String = ""
    
    var startingSegment: [String] = Array()
    @State private var tableContents: [tableText] = [tableText(inputValues: Array(repeating: "0", count: addedValueCount + recordedValueCount))]
    
    // What names do the data entries have and how many are displayed per title
    static let dataEntries: [String] = ["Acclerometer Data (m/s2)", "Velocity (m/s)", "Power per Axis (J)", "Magnitudes (m/s2, J)", "Circuit Values (A, V)"]
    static let dataEntryCount: [Int] = [3, 3, 3, 4, 2]
    
    // What charts and tables are currently active
    @State private var chartDisplays: [Bool] = [true, true] + Array(repeating: false, count: dataEntries.count - 2)
    @State private var tableDisplays: [Bool] = [true, true] + Array(repeating: false, count: dataEntries.count - 2)
    
    var body: some View {
        VStack {
            Text("Accelerometer Data").font(.largeTitle)
            Text("Duration: \(String(format: "%.1f", counter))s - Update: \(String(format: "%.2f", dRand))")
            HStack {
                Button("Settings and Infromation", systemImage: "gearshape.fill") {
                    settingsPopup = true
                }
                .labelStyle(.iconOnly)
                .popover(isPresented: $settingsPopup) {
                    settingView(
                        currentSettings: $settings.currentSettings,
                        defaultSettings: settings.defaultSettings,
                        popup: $settingsPopup
                    )
                }
                
                // Lets user choose charts/tables to display according to limitations
                restrictedMenuSelection(
                    menuName: "Charts",
                    valueLimit: 2,
                    boolArray: $chartDisplays
                )
                
                
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
                chartDisplays: $chartDisplays
            )
            
            // Add the tables to use the real-time data
            // TODO: Add toggle to show tables when recording is stopped
            switch recording {
            case false:
                Button("Show Tables") {
                    tablePopup = true
                }
                .popover(isPresented: $tablePopup) {
                    tableView(
                        currentSettings: settings.currentSettings,
                        tableContents: $tableContents,
                        dataEntryCount: ContentView.dataEntryCount,
                        tableDisplays: $tableDisplays,
                        popup: $tablePopup
                    )
                }
            case true:
                EmptyView()
            }
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
        
        let stepTime: Double = settings.currentSettings["StepTime"] ?? 0.1
        
        // Start timer according to set values
        countTimer = Timer.scheduledTimer(withTimeInterval: stepTime, repeats: true) { timer in
            counter += stepTime
            dRand = Double.random(in: 0.00...1.00)
        }
        
        // Start recording accelerometer updates
      if motionManager.isDeviceMotionAvailable {
            self.motionManager.deviceMotionUpdateInterval = stepTime
            accelTimer = Timer.scheduledTimer(withTimeInterval: stepTime, repeats: true) { timer in
                motionManager.startDeviceMotionUpdates(to: .main) {
                    (data, _) in guard let accelerometerData = data else { return }
                    bulkAccelData = [
                        counter,
                        accelerometerData.userAcceleration.x,
                        accelerometerData.userAcceleration.y,
                        accelerometerData.userAcceleration.z
                    ]
                   
                     let currentRecordedData = recordedData(
                        valueRange: bulkAccelData,
                        pastVelocity: pastVelocity,
                        pastMagnitudes: pastMagnitudes,
                        currentSettings: settings.currentSettings
                    )

                    stored.addToDisplayData(currentRecordedData)
                
                    pastVelocity = [
                        currentRecordedData.vX,
                        currentRecordedData.vY,
                        currentRecordedData.vZ
                    ]
                    pastMagnitudes = [
                        currentRecordedData.aM,
                        currentRecordedData.pM
                    ]
                }
            }
        }
        // Only for preview in development
        else {
            accelTimer = Timer.scheduledTimer(withTimeInterval: stepTime, repeats: true) { timer in
                bulkAccelData = [
                    counter,
                    Double.random(in: -1.000...1.000),
                    Double.random(in: -1.000...1.000),
                    Double.random(in: -1.000...1.000)
                ]
                
                let currentRecordedData = recordedData(
                    valueRange: bulkAccelData,
                    pastVelocity: pastVelocity,
                    pastMagnitudes: pastMagnitudes,
                    currentSettings: settings.currentSettings
                )
                
                stored.addToDisplayData(currentRecordedData)
                
                pastVelocity = [
                    currentRecordedData.vX,
                    currentRecordedData.vY,
                    currentRecordedData.vZ
                ]
                pastMagnitudes = [
                    currentRecordedData.aM,
                    currentRecordedData.pM
                ]
            }
        }
    }
    
    /*
     Stops timers and accelerometer recordings
     Tabulates data for display and exporting
     */
    func stopRecording() {
        // Stop updates and timers
        self.motionManager.stopDeviceMotionUpdates()
        countTimer?.invalidate()
        countTimer = nil
        
        accelTimer?.invalidate()
        accelTimer = nil
        
        // Tablulate data
        // TODO: p/ke not going to .3 or adding e-3 (FOUND: In specific chart for values they are redefined)
        
        // Values after decimal to display
        let settingsFormat = "%.\(String(Int(settings.currentSettings["TableValueLength"] ?? 3)))f"
        
        for (i, _) in stored.displayData.enumerated() {
            let timeString = String(format: "%.1f", stored.displayData[i].t)
            
            // Adding and formatting variables
            let aXString = String(format: settingsFormat, stored.displayData[i].aX)
            let aYString = String(format: settingsFormat, stored.displayData[i].aY)
            let aZString = String(format: settingsFormat, stored.displayData[i].aZ)
            
            let vXString = String(format: settingsFormat, stored.displayData[i].vX)
            let vYString = String(format: settingsFormat, stored.displayData[i].vY)
            let vZString = String(format: settingsFormat, stored.displayData[i].vZ)
            
            let pXString = String(format: settingsFormat, stored.displayData[i].pX * 1000) + "e-3"
            let pYString = String(format: settingsFormat, stored.displayData[i].pY * 1000) + "e-3"
            let pZString = String(format: settingsFormat, stored.displayData[i].pZ * 1000) + "e-3"
            
            let aMString = String(format: settingsFormat, stored.displayData[i].aM)
            let adMString = String(format: settingsFormat, stored.displayData[i].adM)
            let pMString = String(format: settingsFormat, stored.displayData[i].pM)
            let pdMString = String(format: settingsFormat, stored.displayData[i].pdM)
            
            let iString = String(format: settingsFormat, stored.displayData[i].i)
            let vString = String(format: settingsFormat, stored.displayData[i].v)
            
            // Saving row
            let segment: [String] = [timeString, aXString, aYString, aZString, vXString, vYString, vZString, pXString, pYString, pZString, aMString, adMString, pMString, pdMString, iString, vString]
            
            csvText += segment.joined(separator: ",") + "\n"
            
            tableContents.append(tableText(inputValues: segment))
        }
    }
}

// For allowing user selection of a limited number of options
struct restrictedMenuSelection: View {
    // Name displayed on menu button
    let menuName: String
    
    // Number of values that can be true at once
    let valueLimit: Int
    
    // Array to conditionally flip
    @Binding var boolArray: [Bool]
    
    var body: some View {
        Menu(menuName) {
            ForEach(0..<ContentView.dataEntries.count, id: \.self) { i in
                Toggle(ContentView.dataEntries[i], isOn: $boolArray[i]).disabled(valueLimit == boolArray.filter {$0}.count && !boolArray[i])
            }
        }
        .menuActionDismissBehavior(.disabled)
        .buttonStyle(.bordered)
    }
}

#Preview {
    ContentView()
}
