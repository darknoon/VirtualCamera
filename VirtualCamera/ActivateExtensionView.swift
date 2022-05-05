//
//  ContentView.swift
//  VirtualCamera
//
//  Created by Andrew Pouliot on 5/4/22.
//

import SwiftUI

/// TODO: replace this with your extension's Bundle ID. AFACT, you need to end it with `.avextension` to indicate the extension type
let avExtensionIdentifier = "com.darknoon.VirtualCamera.avextension"

struct ActivateExtensionView: View {

    @StateObject var activation = SystemExtensionActivationRequestor(extensionIdentifier: avExtensionIdentifier)
    
    var body: some View {
        ActivationStatusView(activation.status,
                             activate: activation.requestActivation,
                             deactivate: activation.requestDeactivation,
                             openSystemPreferences: activation.openSystemPreferences)
    }
}

struct ActivationStatusView: View {
    
    let activationStatus: SystemExtensionActivationRequestor.Status
    
    // Callbacks to take action
    private let activate: () -> Void?
    private let deactivate: () -> Void?
    private let openSystemPreferences: () -> Void?
    
    init(_ activationStatus: SystemExtensionActivationRequestor.Status,
         activate: @escaping () -> Void = {},
         deactivate: @escaping () -> Void = {},
         openSystemPreferences: @escaping () -> Void = {}
    ) {
        self.activationStatus = activationStatus
        self.activate = activate
        self.deactivate = deactivate
        self.openSystemPreferences = openSystemPreferences
    }

    @ViewBuilder var statusDisplay: some View {
        switch activationStatus {
        case .idle:
            Text("􀥮 Camera Extension")
                .font(.largeTitle)
            Text("To use this extension it must be activated")
                .padding(.top)
            Button("Install") {
                activate()
            }

        case .activated:
            (Text("􀁣").foregroundColor(.green) + Text(" ") + Text("Installed"))
                .font(.largeTitle)
                .padding(.bottom, 10.0)
            Text("To use, select this camera in any app that supports video input")
            Button("Uninstall") {
                deactivate()
            }

        case .requested:
            Text("Requested Activation…")

        case .failed(let error):
            (Text("􀀳").foregroundColor(.red) + Text(" ") + Text("Installation Failed"))
                .font(.largeTitle)
            Text("\(SystemExtensionActivationRequestor.describe(error: error))")
                .padding(.top)

        case .needsUserApproval:
            (Text("􀒳").foregroundColor(.orange) + Text(" ") + Text("Permission Required"))
                .font(.largeTitle)
            Text("Select Allow in System Preferences install the Camera Extension")
                .padding(.top)
            Button("Open System Preferences…") {
                openSystemPreferences()
            }

        case .needsReboot:
            Text("Activated on next reboot")

        case .requestedDeactivation:
            Text("Deactivating")
        }

    }

    
    var body: some View {
        VStack(alignment: .leading) {
            statusDisplay
        }
        .padding()
        .frame(width: 400, height: 300, alignment: .center)
    }
}

struct ActivationStatus_Previews: PreviewProvider {
    
    static let simulatedFailure = SystemExtensionActivationRequestor.Failure.simulatedFailure

    static var previews: some View {
        Group{
            ActivationStatusView(.idle)
            ActivationStatusView(.requested)
            ActivationStatusView(.activated)
            ActivationStatusView(.failed(simulatedFailure))
            ActivationStatusView(.needsUserApproval)
        }.previewLayout(.sizeThatFits)
    }
}
