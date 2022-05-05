//
//  main.swift
//  VirtualCameraExtension
//
//  Created by Andrew Pouliot on 5/4/22.
//

import Foundation
import CoreMediaIO

let providerSource = VirtualCameraExtensionProviderSource(clientQueue: nil)
CMIOExtensionProvider.startService(provider: providerSource.provider)

CFRunLoopRun()
