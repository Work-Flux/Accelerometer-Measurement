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
 TODO: Try and find more elegent method of display and variable assignment
    Horizontal line between titles and data
 
 FIXME: Tables display multiple entries at the same timestamp when at high cpu usage (117.6, 117.6 ...)
 FIXME: Header values for tables not aligned with interior data
 */

// Struct for displaying tables
struct tableView: View {
    // The settings data
    var currentSettings: [String : Double]
    
    private var unwrappedLength: Int {
        Int(currentSettings["TableValueLength"] ?? 3)
    }
    
    private let tableDataSize: CGFloat = 10
    
    // The passed external data that is displayed
    @Binding var displayedData: [recordedData]
    
    // What number of entries are under each table group selection, and which ones are active
    let dataEntryCount: [Int]
    @Binding var tableDisplays: [Bool]
    
    // If the sheet is active
    @Binding var sheet: Bool
    
    var body: some View {
        HStack {
            restrictedMenuSelection( // Defined in ContentView
                menuName: "Select Columns",
                valueLimit: 2,
                boolArray: $tableDisplays
            )
            Button("Hide Table") {
                sheet = false
            }
            .padding()
            .buttonStyle(.bordered)
        }
        
        // Setup column headers
        HStack() {
            fittedText(text: "Time")
            if tableDisplays[0] {
                fittedText(text: "aX")
                fittedText(text: "aY")
                fittedText(text: "aZ")
            }
            
            if tableDisplays[1] {
                fittedText(text: "vX")
                fittedText(text: "vY")
                fittedText(text: "vZ")
            }
            
            if tableDisplays[2] {
                fittedText(text: "pX")
                fittedText(text: "pY")
                fittedText(text: "pZ")
            }
            
            if tableDisplays[3] {
                fittedText(text: "a.M")
                fittedText(text: "∆a.M")
                fittedText(text: "p.M")
                fittedText(text: "∆p.M")
            }
            
            if tableDisplays[4] {
                fittedText(text: "I")
                fittedText(text: "V")
            }
        }
        
        // Scrollable selection for entire table data
        ScrollView{
            LazyVStack(alignment: .leading) {
                ForEach(displayedData) { data in
                    HStack() {
                        formattedTableText(text: data.t.formatted(.number.precision(.fractionLength(1))), size: tableDataSize)
                        
                        if tableDisplays[0] {
                            formattedTableText(text: data.aX.formatSignedPrecision(precision: unwrappedLength), size: tableDataSize)
                            formattedTableText(text: data.aY.formatSignedPrecision(precision: unwrappedLength), size: tableDataSize)
                            formattedTableText(text: data.aZ.formatSignedPrecision(precision: unwrappedLength), size: tableDataSize)
                        }
                        if tableDisplays[1] {
                            formattedTableText(text: data.vX.formatSignedPrecision(precision: unwrappedLength), size: tableDataSize)
                            formattedTableText(text: data.vY.formatSignedPrecision(precision: unwrappedLength), size: tableDataSize)
                            formattedTableText(text: data.vZ.formatSignedPrecision(precision: unwrappedLength), size: tableDataSize)
                        }
                        if tableDisplays[2] {
                            formattedTableText(text: data.pX.formatSignedExponential(precision: unwrappedLength), size: tableDataSize)
                            formattedTableText(text: data.pY.formatSignedExponential(precision: unwrappedLength), size: tableDataSize)
                            formattedTableText(text: data.pZ.formatSignedExponential(precision: unwrappedLength), size: tableDataSize)
                        }
                        if tableDisplays[3] {
                            formattedTableText(text: data.aM.formatSignedPrecision(precision: unwrappedLength), size: tableDataSize)
                            formattedTableText(text: data.adM.formatSignedPrecision(precision: unwrappedLength), size: tableDataSize)
                            formattedTableText(text: data.pM.formatSignedPrecision(precision: unwrappedLength), size: tableDataSize)
                            formattedTableText(text: data.pdM.formatSignedPrecision(precision: unwrappedLength), size: tableDataSize)
                        }
                        if tableDisplays[4] {
                            formattedTableText(text: data.i.formatSignedPrecision(precision: unwrappedLength), size: tableDataSize)
                            formattedTableText(text: data.v.formatSignedPrecision(precision: unwrappedLength), size: tableDataSize)
                        }
                    }
                }
            }
            .padding()
        }
        .defaultScrollAnchor(UnitPoint.bottom)
    }
}

// Struct storing data for all potential table columns at a single time
struct tableText: Identifiable {
    // Time for row of value
    let timeString: String
    // Acceleration along each axis
    let aXString: String
    let aYString: String
    let aZString: String
    // Velocity along each axis
    let vXString: String
    let vYString: String
    let vZString: String
    // Power resulting from mass, acceleration, velocity
    let pXString: String
    let pYString: String
    let pZString: String
    // Magnitudes of acceleration and changes of them
    let aMString: String
    let adMString: String
    let pMString: String
    let pdMString: String
    // Current and velocity from magnitudes of power and resistance
    let iString: String
    let vString: String
    
    let id = UUID()
    
    init(inputValues: [String]) {
        self.timeString = inputValues[0]
        self.aXString = inputValues[1]
        self.aYString = inputValues[2]
        self.aZString = inputValues[3]
        self.vXString = inputValues[4]
        self.vYString = inputValues[5]
        self.vZString = inputValues[6]
        self.pXString = inputValues[7]
        self.pYString = inputValues[8]
        self.pZString = inputValues[9]
        self.aMString = inputValues[10]
        self.adMString = inputValues[11]
        self.pMString = inputValues[12]
        self.pdMString = inputValues[13]
        self.iString = inputValues[14]
        self.vString = inputValues[15]
    }
}

extension Double {
    func formatSignedPrecision(precision: Int) -> String {
        self.formatted(.number
            .precision(.fractionLength(precision))
            .sign(strategy: .always(includingZero: true)))
    }
    
    func formatSignedExponential(precision: Int) -> String {
        self.formatted(.number
            .precision(.fractionLength(precision - 2))
            .sign(strategy: .always(includingZero: true))
            .notation(.scientific))
    }
}

struct formattedTableText: View {
    let text: String
    let size: CGFloat
    
    var body: some View {
        Text(text)
            .monospaced()
            .font(.system(size: size))
            .frame(maxWidth: .infinity, alignment: .leading)
        
    }
}

struct fittedText: View {
    let text: String
    
    var body: some View {
        Text(text)
            .frame(maxWidth: .infinity)
    }
}
