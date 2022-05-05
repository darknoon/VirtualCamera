import SystemExtensions
import AppKit

/// A helper class for your containing app that manages requesting activation
/// Note: you must install your app in the Applications folder to be able to install a System Extension from it
class SystemExtensionActivationRequestor: NSObject, OSSystemExtensionRequestDelegate, ObservableObject {
    
    let extensionIdentifier: String
    
    init(extensionIdentifier: String) {
        self.extensionIdentifier = extensionIdentifier
        super.init()
        if !appIsInstalledInValidLocation {
            status = .failed(Failure.appInstalledInInvalidLocation(Bundle.main.bundleURL))
        }
    }
    
    enum Status {
        case idle
        case requested
        case needsUserApproval
        case needsReboot
        case activated
        case failed(Error)
        case requestedDeactivation
    }
    
    enum Failure: Error {
        case unknownRequestResult(OSSystemExtensionRequest.Result)
        case simulatedFailure
        case appInstalledInInvalidLocation(URL)
    }
    
    @Published var status: Status = .idle
    
    // Preflight check to make sure we're in /Applications etc
    var appIsInstalledInValidLocation: Bool {
        let canonical = Bundle.main.bundleURL.absoluteURL.resolvingSymlinksInPath()
        let parentDir = canonical.deletingLastPathComponent()
        
        return parentDir.path == "/Applications"
    }
    
    func openSystemPreferences() {
        let special = URL(string: "x-apple.systempreferences:com.apple.preference.security?general")!
        NSWorkspace.shared.open(special)
    }
    
    func requestActivation() {
        guard case .idle = status
        else { fatalError("Invalid state") }
        
        print("Requesting activation of extension \"\(extensionIdentifier)\"")
        let req = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: extensionIdentifier, queue: DispatchQueue.main)
        req.delegate = self
        
        OSSystemExtensionManager.shared.submitRequest(req)
        
        status = .requested
    }
    
    func requestDeactivation() {
        guard case .activated = status
        else { fatalError("Invalid state to request deactivation") }

        print("Requesting deactivation of extension \"\(extensionIdentifier)\"")
        let req = OSSystemExtensionRequest.deactivationRequest(forExtensionWithIdentifier: extensionIdentifier, queue: DispatchQueue.main)
        req.delegate = self

        OSSystemExtensionManager.shared.submitRequest(req)

        status = .requestedDeactivation
    }

    
    func request(_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension ext: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {
        print("Asked to resolve extension replacement \"\(extensionIdentifier)\" existing: \(existing) new: \(ext)")
        // Replace by default?
        return .replace
    }
    
    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        print("Needs user approval for \"\(extensionIdentifier)\" request: \(request)")
        status = .needsUserApproval
    }
    
    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        print("Request finished \"\(extensionIdentifier)\" result: \(result)")
        
        // We should be either requesting activation or deactivation
        switch status {
        case .requested:
            switch result {
            case .completed:
                status = .activated
            case .willCompleteAfterReboot:
                status = .needsReboot
            @unknown default:
                status = .failed(Failure.unknownRequestResult(result))
            }
        case .requestedDeactivation:
            switch result {
            case .completed:
                status = .idle
            case .willCompleteAfterReboot:
                status = .needsReboot
            @unknown default:
                status = .failed(Failure.unknownRequestResult(result))
            }
        default:
            assertionFailure("Invalid internal state for OSSystemExtensionRequest finish \(status)")
        }
        
    }
    
    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        print("Extension \"\(extensionIdentifier)\" activation failed: \(error)")
        status = .failed(error)
    }

    static func describe(error: Error) -> String {
        if let error = error as? OSSystemExtensionError {
            switch error.code {
            case .unknown:
                return "Unknown"
            case .missingEntitlement:
                return "Missing Entitlement"
            case .unsupportedParentBundleLocation:
                return "Unsupported Parent Bundle Location"
            case .extensionNotFound:
                return "Extension Not found"
            case .extensionMissingIdentifier:
                return "Extension Missing Identifier"
            case .duplicateExtensionIdentifer:
                return "Duplicate Extension Identifier"
            case .unknownExtensionCategory:
                return "Unknown Extension Category"
            case .codeSignatureInvalid:
                return "Code Signature Invalid"
            case .validationFailed:
                return "Validation Failed"
            case .forbiddenBySystemPolicy:
                return "Forbidden by System Policy"
            case .requestCanceled:
                return "Request Cancelled"
            case .requestSuperseded:
                return "Request Superceeded"
            case .authorizationRequired:
                return "Authorization Required"
            @unknown default:
                return error.localizedDescription
            }
        } else if let error = error as? Failure {
            switch error {
            case .unknownRequestResult(let result):
                return "System Extension Service returned an unexpected result: \(result)"
            case .simulatedFailure:
                return "This is a simulated failure"
            case .appInstalledInInvalidLocation(let url):
                return "This app is installed in an unsupported location:\n\(url.path)\nYou must install it in the Applications folder"
            }
        }
        return error.localizedDescription
    }

}

