//
//  SettingsView.swift
//  Accelerometer Measurement
//
//  Created by Finn Luxton on 25/06/2025.
//

import SwiftUI

/*
 Section for displaying the settings pop-up page, allowing the user to modify the values used for calculating details for charts / tables
 
 Contains:
    Struct for displaying full settings page
    Struct for boilerplate section of a form
        Header + option for toggle + numeric textfield
 
 TODO: Make display settings
 TODO: Check how implemented textField clarifier in numericInputView interacts with macOS titling
 */

// Settings pop-up page
struct settingView: View {
    // The settings data
    @Binding var currentSettings: [String : Double]
    
    // If the popup is active
    @Binding var popup: Bool
    
    @State private var resistance: Double = 1
    
    var body: some View {
        Form {
            // View for choosing to use mass or use mass-specific
            numericInputView(
                headerText: "Mass",
                externalDictionary: $currentSettings,
                dictionaryKey: "Mass",
                defaultDictionaryValue: 1,
                useToggle: true,
                toggleText: "Mass On",
                useToggleSubtext: true,
                toggleOffSubtext: "Will generate mass-specific data",
                textFieldClarifier: "Mass (Kg):",
                textFieldPlaceholder: "Input Mass"
            )
            
            // View for assuming zero or non-zero initial kinetic energy
            numericInputView(
                headerText: "Starting Kinetic Energy",
                externalDictionary: $currentSettings,
                dictionaryKey: "KE_0",
                defaultDictionaryValue: 0,
                toggleValue: false,
                useToggle: true,
                toggleText: "Moving Start",
                useToggleSubtext: true,
                toggleOffSubtext: "Assuming starting velocity of zero",
                textFieldClarifier: "Starting KE (J):",
                textFieldPlaceholder: "Starting Kinetic Energy"
            )
            
            // View for getting the theoretical resistance used when doing calculations
            numericInputView(
                headerText: "Circuit Resistance",
                externalDictionary: $currentSettings,
                dictionaryKey: "Resistance",
                defaultDictionaryValue: 1,
                useToggle: false,
                useToggleSubtext: false,
                textFieldClarifier: "Resistance (Ω):",
                textFieldPlaceholder: "Resistance"
            )
        }
        
        VStack {
            Text("Settings Check").font(.title)
            Text("Mass (g) is \(String(format: "%.3e", currentSettings["Mass"] ?? 1))") // Mass in kg
            Text("Starting Kinetic Energy (J) is  \(String(format: "%.3e", currentSettings["KE_0"] ?? 1))") // Assumed starting kinetic energy in joules
            Text("Resistance (Ω) is  \(String(format: "%.3e", currentSettings["Resistance"] ?? 1))") // Resistance displayed in ohms
        }
    }
}

// Struct for adding a module with a header, and a numeric textfield, with the option of restricting textfield use via toggle
struct numericInputView: View {
    let headerText: String
    
    @Binding var externalDictionary: [String : Double]
    let dictionaryKey: String
    let defaultDictionaryValue: Double
    
    @State var userInputValue: Double = 0
    
    @State var toggleValue: Bool = true
    let useToggle: Bool
    let toggleText: String?
    let useToggleSubtext: Bool
    let toggleOffSubtext: String?
    
    let textFieldClarifier: String
    let textFieldPlaceholder: String
    
    init(
        headerText: String,
        externalDictionary: Binding<[String : Double]>,
        dictionaryKey: String,
        defaultDictionaryValue: Double,
        userInputValue: Double = 0,
        toggleValue: Bool = true,
        useToggle: Bool,
        toggleText: String? = nil,
        useToggleSubtext: Bool,
        toggleOffSubtext: String? = nil,
        textFieldClarifier: String,
        textFieldPlaceholder: String
    ) {
        self.headerText = headerText
        self._externalDictionary = externalDictionary
        self.dictionaryKey = dictionaryKey
        self.defaultDictionaryValue = defaultDictionaryValue
        self.userInputValue = userInputValue
        self.toggleValue = toggleValue
        self.useToggle = useToggle
        self.toggleText = toggleText
        self.useToggleSubtext = useToggleSubtext
        self.toggleOffSubtext = toggleOffSubtext
        self.textFieldClarifier = textFieldClarifier
        self.textFieldPlaceholder = textFieldPlaceholder
    }
    
    var body: some View {
        Section(header: Text(headerText)) {
            switch useToggle {
            case true:
                // The toggle controlling if the textField is active or the default value will be used
                Toggle(isOn: $toggleValue) {
                    Text(toggleText!)
                    
                    if useToggleSubtext && !toggleValue {
                        Text(toggleOffSubtext!)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: toggleValue) {
                    externalDictionary[dictionaryKey] = toggleValue ? userInputValue : defaultDictionaryValue
                }
                // Text confirming what the
                HStack {
                    Text(textFieldClarifier)
                        .foregroundColor(!toggleValue ? .gray : .primary)
                    TextField(textFieldPlaceholder, value: toggleValue ? $userInputValue : .constant(defaultDictionaryValue), format: .number)
                        .disabled(!toggleValue)
                        .foregroundColor(!toggleValue ? .gray : .primary)
                        .keyboardType(.decimalPad)
                        .onAppear {
                            userInputValue = defaultDictionaryValue
                        }
                        .onSubmit {
                            externalDictionary[dictionaryKey] = userInputValue
                        }
                }
            case false:
                HStack {
                    Text(textFieldClarifier)
                    TextField(textFieldPlaceholder, value: $userInputValue, format: .number)
                        .keyboardType(.decimalPad)
                        .onAppear {
                            userInputValue = defaultDictionaryValue
                        }
                        .onSubmit {
                            externalDictionary[dictionaryKey] = userInputValue
                        }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var popup = true
    @Previewable @State var currentSettings: [String: Double] = [:]
    settingView(currentSettings: $currentSettings, popup: $popup)
}
