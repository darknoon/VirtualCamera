/// All of the code below came from the template "Camera Extension" built into Xcode, I did not create any of it.

import Foundation
import CoreMediaIO

let providerSource = VirtualCameraExtensionProviderSource(clientQueue: nil)
CMIOExtensionProvider.startService(provider: providerSource.provider)

CFRunLoopRun()
