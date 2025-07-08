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
 TODO: Add catch for setting timestep to <=0
    
 FIXME: Velocity has negative trend on axis parallel to weight force
    Gravity not properly removed?
    Switched to deviceMotion user updates instead of raw accel but issue still present, readout seems less stable
    Appears to have a similar trend when in other orientations
    Other axes have very minor trends up/down but one is the outlier
 */

// Tick rate for timers / accelerometer updates
let stepTime: Double = 0.01

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
        
        "ChartLength" : 10, // Number of seconds of data to display
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
 TODO: Check stopRecording spiking memory
    Assumed to be due to table writing, needs validation
 TODO: Make duration display updating units (s->m,s->h,m,s)
 */

// Main page view
struct ContentView: View {
    let motionManager = CMMotionManager()
    
    // Real-time repositry for data to be displayed on the charts
    @StateObject var stored = storedData()
    
    // Real-time storage for settings data
    @StateObject var settings = settingsData()
    
    // Timer for steps while recording
    @State private var accelTimer: Timer?
    
    // Duration of current recording
    @State private var counter: Double = 0.0
    
    // If we are recording the accelerometer data
    @State private var recording: Bool = false
    
    // If we are displaying the settings sheet
    @State private var settingsSheet: Bool = false
    
    // If we are displaying the table sheet
    @State private var tableSheet: Bool = false
    
    // Table and export variables
    @State private var csvText: String = ""
    
    // What names do the data entries have and how many are displayed per title
    static let dataEntries: [String] = ["Acclerometer Data (m/s2)", "Velocity (m/s)", "Power per Axis (W)", "Magnitudes (m/s2, W)", "Circuit Values (A, V)"]
    static let dataEntryCount: [Int] = [3, 3, 3, 4, 2]
    
    // What charts and tables are currently active
    @State private var chartDisplays: [Bool] = [true, true] + Array(repeating: false, count: dataEntries.count - 2)
    @State private var tableDisplays: [Bool] = [true, true] + Array(repeating: false, count: dataEntries.count - 2)
    
    var body: some View {
        VStack {
            Text("Accelerometer Data").font(.largeTitle)
            HStack {
                // Opens settings sheet page
                Button("Settings and Infromation", systemImage: "gearshape.fill") { settingsSheet = true }
                    .labelStyle(.iconOnly)
                    .sheet(isPresented: $settingsSheet) {
                        settingView(
                            currentSettings: $settings.currentSettings,
                            defaultSettings: settings.defaultSettings,
                            sheet: $settingsSheet
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
                    Button("Start Recording", systemImage: "play.circle.fill") { startRecording() }
                        .labelStyle(.iconOnly)
                case true:
                    Button("End Recording", systemImage: "stop.circle.fill") { stopRecording() }
                        .labelStyle(.iconOnly)
                }
            }
            
            Text("Duration: \(String(format: "%.1f", counter))s")
            
            // Add the charts to use the real-time data
            chartView(
                displayedData: stored.displayData,
                currentSettings: settings.currentSettings,
                chartDisplays: $chartDisplays
            )
            
            // Add the tables to use the data when processed after recording
            Button("Show Tables") { tableSheet = true }
                .sheet(isPresented: $tableSheet) {
                    tableView(
                        currentSettings: settings.currentSettings,
                        displayedData: $stored.displayData,
                        dataEntryCount: ContentView.dataEntryCount,
                        tableDisplays: $tableDisplays,
                        sheet: $tableSheet
                    )
                }
        }
        .padding()
    }
    
    /*
     Resets stored values
     Starts the motionManager and records acceleration if it is available
     Generates random data for testing if it is not
     Updates stored past values for calculation of changes in values
     */
    func startRecording() {
        // Clear previous values
        stored.displayData.removeAll()
        csvText.removeAll()
        counter = 0.0
        
        recording = true
        
        // Recording previous timestep's theoretical velocity for storedData calculations
        var pastVelocity: [Double] = [0, 0, 0]
        // Recording previous timestep's magnitudes of acceleration and power
        var pastMagnitudes: [Double] = [0, 0]
        
        // Recording accelerometer Data
        var bulkAccelData: [Double] = [0, 0, 0]
        
        let stepTime: Double = settings.currentSettings["StepTime"] ?? 0.1
        
        // Start recording accelerometer updates
        if motionManager.isDeviceMotionAvailable {
            self.motionManager.deviceMotionUpdateInterval = stepTime
            accelTimer = Timer.scheduledTimer(withTimeInterval: stepTime, repeats: true) { timer in
                counter += stepTime
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
        } else { // Should only be used for Xcode preview or similar
            accelTimer = Timer.scheduledTimer(withTimeInterval: stepTime, repeats: true) { timer in
                counter += stepTime
                
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
                
                // Tablulate new data
                // TODO: p/ke not going to .3 or adding e-3 (FOUND: In specific chart for values they are redefined)
            }
        }
    }
    
    /*
     Stops timers and accelerometer recordings
     Sends the condensed form of recordedData at each tick for tabulation and exporting
     */
    func stopRecording() {
        // Stop updates and timers
        self.motionManager.stopDeviceMotionUpdates()
        
        accelTimer?.invalidate()
        accelTimer = nil
        
        recording = false
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
                Toggle(ContentView.dataEntries[i], isOn: $boolArray[i])
                    .disabled(valueLimit == boolArray.filter {$0}.count && !boolArray[i])
            }
        }
        .menuActionDismissBehavior(.disabled)
        .buttonStyle(.bordered)
    }
}

#Preview {
    ContentView()
}
