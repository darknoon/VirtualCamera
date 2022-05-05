import SystemExtensions

/// A helper class for your containing app that manages requesting activation
/// Note: you must install your app in the Applications folder to be able to install a System Extension from it
class SystemExtensionActivationRequestor: NSObject, OSSystemExtensionRequestDelegate, ObservableObject {
    
    let extensionIdentifier: String
    
    init(extensionIdentifier: String) {
        self.extensionIdentifier = extensionIdentifier
    }
    
    enum Status {
        case idle
        case requested
        case needsUserApproval
        case needsReboot
        case activated
        case failed(Error)
    }
    
    enum Failure: Error {
        case unknownRequestResult(OSSystemExtensionRequest.Result)
        case simulatedFailure
    }
    
    @Published var status: Status = .idle
    
    func requestActivation() {
        guard case .idle = status
        else { fatalError("Invalid state") }
        
        print("Requesting activation of extension \"\(extensionIdentifier)\"")
        let req = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: extensionIdentifier, queue: DispatchQueue.main)
        req.delegate = self
        
        OSSystemExtensionManager.shared.submitRequest(req)
        
        status = .requested
        
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
        switch result {
        case .completed:
            status = .activated
        case .willCompleteAfterReboot:
            status = .needsReboot
        @unknown default:
            status = .failed(Failure.unknownRequestResult(result))
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
                return "OSSystemExtensionError Unknown"
            case .missingEntitlement:
                return "OSSystemExtensionError Missing Entitlement"
            case .unsupportedParentBundleLocation:
                return "OSSystemExtensionError Unsupported Parent Bundle Location"
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
        }
        return error.localizedDescription
    }

}

let avExtensionIdentifier = "com.darknoon.VirtualCamera.avextension"

