//
//  ContentView.swift
//  VirtualCamera
//
//  Created by Andrew Pouliot on 5/4/22.
//

import SwiftUI

struct ContentView: View {

    @StateObject var activation = SystemExtensionActivationRequestor(extensionIdentifier: avExtensionIdentifier)
    
    var body: some View {
        ActivationStatus(activationStatus: activation.status)
            .onAppear {
                activation.requestActivation()
            }
    }
}

struct ActivationStatus: View {
    
    let activationStatus: SystemExtensionActivationRequestor.Status
    
    @ViewBuilder var statusDisplay: some View {
        switch activationStatus {
        case .idle:
            Text("Not requested")
        case .activated:
            Text("Activated")
        case .requested:
            Text("Requested Activation. Open System Preferences to complete…")
        case .failed(let error):
            Text("Activation Failed: \(SystemExtensionActivationRequestor.describe(error: error))")
        case .needsUserApproval:
            Text("Activation requires user approval")
        case .needsReboot:
            Text("Activated on next reboot")
        }
    }

    
    var body: some View {
        VStack {
            Text("Extension Activation")
                .font(.headline)
            statusDisplay
        }.frame(width: 400, height: 300, alignment: .center)
    }
}

struct ActivationStatus_Previews: PreviewProvider {
    static var previews: some View {
        Group{
        ActivationStatus(activationStatus: .requested)
        ActivationStatus(activationStatus: .failed(SystemExtensionActivationRequestor.Failure.simulatedFailure))
        }.previewLayout(.sizeThatFits)
    }
}
