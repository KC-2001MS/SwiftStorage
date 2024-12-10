//
//  ContentView.swift
//  Sample
//  
//  Created by Keisuke Chinone on 2024/07/07.
//


import SwiftUI
import SwiftStorage

struct ContentView: View {
    @State private var settings = SettingsObject()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 10) {
                        Text("Wellcome to SwiftStorage")
#if os(watchOS)
                            .font(.headline)
#else
                            .font(.title)
#endif
                        
                        Text("Framework for storing data without using Key Value")
                            .font(.body)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.vertical, 50)
                    .frame(maxWidth: .infinity)
                }
                
                Section {
                    Toggle("Support for Observation framework", isOn: $settings.isObservationSupported)
                    
                    Toggle("Can be disabled on a per-property basis", isOn: $settings.isDisabledOnAPerPropertyLevel)
                    
                    Toggle("Save in UserDefaults", isOn: $settings.isStoredInUserDefaults)
                    
                    Toggle("Save in Key Value Store", isOn: $settings.isStoredInKeyValueStore)
                    
                    Toggle("Specify keys individually", isOn: $settings.isSpecifiedIndividually)
                    
                    Toggle("Key Value Store and UserDefaults together", isOn: $settings.isPossibleToUseKeyValueStoreAndUserDefaultsTogether)
                } header: {
                    Text("Features")
                }
                
                Section {
                    Toggle("Sample Bool", isOn: $settings.sampleBool)
                    
#if !os(tvOS)
                    Stepper("Sample Int: \(settings.sampleInt)", value: $settings.sampleInt)
                    
                    Slider(value: $settings.sampleDouble, in: 0...10) {
                        Text("Sample Double: \(settings.sampleDouble)")
                    }
                    
                    Slider(value: $settings.sampleFloat, in: 0...10) {
                        Text("Sample Float: \(settings.sampleFloat)")
                    }
                    #endif
                    TextField("Sample String", text: $settings.sampleString)
                    
#if !os(tvOS)
                    DatePicker(
                            "Sample Date",
                            selection: $settings.sampleDate,
                            displayedComponents: [.date]
                    )
#endif
                } header: {
                    Text("Sample Data")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("SwiftStorage Sample")
        }
#if os(macOS) || os(visionOS)
        .frame(minWidth: 500,maxWidth: 700, minHeight: 600, maxHeight: 800)
#endif
#if os(macOS)
        .containerBackground(Material.regular, for: .window)
        .toolbar(removing: .title)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .windowMinimizeBehavior(.disabled)
        .windowFullScreenBehavior(.disabled)
#endif
    }
}

#Preview {
    ContentView()
}
