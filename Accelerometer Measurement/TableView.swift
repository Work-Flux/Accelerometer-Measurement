//
//  TableView.swift
//  Accelerometer Measurement
//
//  Created by Finn Luxton on 24/06/2025.
//

import SwiftUI

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
struct tableView: View {
    // The settings data
    var currentSettings: [String : Double]
    
    // What is the contents of the table
    @Binding var tableContents: [tableText]
    
    // What names do the data entries have and where are they displayed
    let dataEntries: [String]
    let dataEntryCount: [Int]
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
