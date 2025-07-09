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
 TODO: Check init for setting default displayed values instead of onAppear as manual values are not displayed when sheet re-appears
 TODO: Add single-choice list for selecting starting velocity direction
    Currently assumed to be y
    Might need to add orientator for axes
 
 FIXME: First interaction with textfields is delayed
 */

// Settings pop-up page
struct settingView: View {
    // The settings data
    @Binding var currentSettings: [String : Double]
    let defaultSettings: [String : Double]
    
    // If the sheet is active
    @Binding var sheet: Bool
    
    // For dynamic resizing of settings check sheet
    @State var checksheetHight: CGFloat = .zero
    // For opening the visual check for settings
    @State var settingsChecksheet: Bool = false
    
    var body: some View {
        Form {
            // Choosing to use mass or use mass-specific values
            numericInputView(
                headerText: "Mass",
                externalDictionary: $currentSettings,
                dictionaryKey: "Mass",
                defaultDictionary: defaultSettings,
                useToggle: true,
                toggleText: "Mass On",
                useToggleSubtext: true,
                toggleOffSubtext: "Will generate mass-specific data",
                textFieldClarifier: "Mass (kg):",
                textFieldPlaceholder: "Input mass"
            )
            
            // Determining zero or non-zero initial velocity
            numericInputView(
                headerText: "Starting Velocity",
                externalDictionary: $currentSettings,
                dictionaryKey: "V0",
                defaultDictionary: defaultSettings,
                useToggle: true,
                toggleValue: false,
                toggleText: "Moving Start",
                useToggleSubtext: true,
                toggleOffSubtext: "Assuming starting speed of zero",
                textFieldClarifier: "Velocity (m/s):",
                textFieldPlaceholder: "Starting velocity"
            )
            
            // Getting the theoretical resistance used when doing calculations
            numericInputView(
                headerText: "Circuit Resistance",
                externalDictionary: $currentSettings,
                dictionaryKey: "Resistance",
                defaultDictionary: defaultSettings,
                useToggle: false,
                useToggleSubtext: false,
                textFieldClarifier: "Resistance (Ω):",
                textFieldPlaceholder: "Resistance"
            )
            
            // Changing the number of seconds of data displayed in the overview charts
            numericInputView(
                headerText: "Tick Rate",
                externalDictionary: $currentSettings,
                dictionaryKey: "tickRate",
                defaultDictionary: defaultSettings,
                useToggle: false,
                useToggleSubtext: false,
                textFieldClarifier: "Seconds (s):",
                textFieldPlaceholder: "Update rate"
            )
            
            // Changing the number of seconds of data displayed in the overview charts
            numericInputView(
                headerText: "Chart Length",
                externalDictionary: $currentSettings,
                dictionaryKey: "ChartLength",
                defaultDictionary: defaultSettings,
                useToggle: false,
                useToggleSubtext: false,
                textFieldClarifier: "Seconds (s):",
                textFieldPlaceholder: "Display length"
            )
            
            // How many decimals are displayed in the values within the table pop-up
            numericInputView(
                headerText: "Table Value Length",
                externalDictionary: $currentSettings,
                dictionaryKey: "TableValueLength",
                defaultDictionary: defaultSettings,
                useToggle: false,
                useToggleSubtext: false,
                textFieldClarifier: "Length:",
                textFieldPlaceholder: "Digits shown after the decimal"
            )
            
            Section {
                Button("Check Settings") { settingsChecksheet = true }
                    .sheet(isPresented: $settingsChecksheet) {
                        VStack {
                            ForEach(currentSettings.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                Text("\(key): \(value.formatted(.number))")
                            }
                            
                            Divider()
                            
                            Button("Close") {
                                settingsChecksheet = false
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        .fixedSize(horizontal: false, vertical: true)
                        .modifier(GetHeightModifier(height: $checksheetHight))
                        .presentationDetents([.height(checksheetHight)])
                    }
                Button("Close Settings") {
                    sheet = false
                }
            }
            
            Section {
                Button("Reset Settings", role: .destructive) {
                    currentSettings = defaultSettings
                }
                
            }
        }
    }
}

// Struct for adding a module with a header, and a numeric textfield, with the option of restricting textfield use via toggle
struct numericInputView: View {
    // Title for the section generated
    let headerText: String
    
    // External dictionary being modified by the settings
    @Binding var externalDictionary: [String : Double]
    // Key to modify in dictionary
    let dictionaryKey: String
    // Value that is displayed on initial load and when the section is toggled off
    let defaultDictionary: [String : Double]
    
    // The stored value that the user inputs
    @State private var userInputValue: Double?
    
    // Whether the toggle is displayed or not
    let useToggle: Bool
    // Starting state of the toggle and its stored value
    @State var toggleValue: Bool = true
    // Descriptor for the toggle
    let toggleText: String?
    
    // Whether the subtext is used
    let useToggleSubtext: Bool
    // Subtext that displays when toggle is turned off
    let toggleOffSubtext: String?
    
    // Text describing the input requested by the textfield
    let textFieldClarifier: String
    // Text that displays when no value is in the textfield
    let textFieldPlaceholder: String
    // Whether the textfield is selected or not
    @FocusState private var textFieldFocused: Bool
    
    init(
        headerText: String,
        externalDictionary: Binding<[String : Double]>,
        dictionaryKey: String,
        defaultDictionary: [String : Double],
        useToggle: Bool,
        toggleValue: Bool = true,
        toggleText: String? = nil,
        useToggleSubtext: Bool,
        toggleOffSubtext: String? = nil,
        textFieldClarifier: String,
        textFieldPlaceholder: String
    ) {
        self.headerText = headerText
        self._externalDictionary = externalDictionary
        self.dictionaryKey = dictionaryKey
        self.defaultDictionary = defaultDictionary
        self.userInputValue = defaultDictionary[dictionaryKey]
        self.useToggle = useToggle
        self.toggleValue = toggleValue
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
                Toggle(isOn: $toggleValue) {
                    Text(toggleText!)
                    
                    if useToggleSubtext && !toggleValue {
                        Text(toggleOffSubtext!)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: toggleValue) {
                    externalDictionary[dictionaryKey] = toggleValue ? userInputValue : defaultDictionary[dictionaryKey]
                }
                HStack {
                    Text(textFieldClarifier)
                        .foregroundColor(!toggleValue ? .gray : .primary)
                    TextField(textFieldPlaceholder, value: toggleValue ? $userInputValue : .constant(defaultDictionary[dictionaryKey]), format: .number)
                        .disabled(!toggleValue)
                        .foregroundColor(!toggleValue ? .gray : .primary)
                        .keyboardType(.decimalPad)
                        .focused($textFieldFocused)
                        .onSubmit {
                            externalDictionary[dictionaryKey] = userInputValue
                        }
                        .onAppear {
                            userInputValue = toggleValue ? externalDictionary[dictionaryKey] ?? defaultDictionary[dictionaryKey]! : defaultDictionary[dictionaryKey]!
                        }
                    if textFieldFocused {
                        Button("Submit") {
                            textFieldFocused = false
                            externalDictionary[dictionaryKey] = userInputValue
                        }
                    }
                }
            case false:
                HStack {
                    Text(textFieldClarifier)
                    TextField(textFieldPlaceholder, value: $userInputValue, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($textFieldFocused)
                        .onSubmit {
                            externalDictionary[dictionaryKey] = userInputValue
                        }
                        .onAppear {
                            userInputValue = externalDictionary[dictionaryKey] ?? defaultDictionary[dictionaryKey]!
                        }
                    if textFieldFocused {
                        Button("Submit") {
                            textFieldFocused = false
                            externalDictionary[dictionaryKey] = userInputValue
                        }
                    }
                }
            }
        }
    }
}

struct GetHeightModifier: ViewModifier {
    @Binding var height: CGFloat

    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geo -> Color in
                DispatchQueue.main.async {
                    height = geo.size.height
                }
                return Color.clear
            }
        )
    }
}

#Preview {
    @Previewable @State var sheet = true
    
    @Previewable let defaultSettings: [String: Double] = settingsData().defaultSettings
    
    @Previewable @State var currentSettings: [String: Double] = settingsData().currentSettings
    
    settingView(currentSettings: $currentSettings, defaultSettings: defaultSettings, sheet: $sheet)
}
