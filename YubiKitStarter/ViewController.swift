// Copyright 2018-2019 Yubico AB
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//  About: This is the main view controller that tracks the YubiKey session state (connected or not connected and displays the key details such as serial number and firmware.
import UIKit

class ViewController: LightningInteractionViewController {

    @IBOutlet weak var lblKeyInserted: UILabel!
    @IBOutlet weak var lblSerial: UILabel!
    @IBOutlet weak var lblFirmware: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            // Make sure the session is started
            YubiKitManager.shared.keySession.startSession()

            // Enable state observation (see LightningInteractionViewController)
            observeSessionStateUpdates = true

            // Update the key session data manually when app loads
            //keySessionStateDidChange()

        } else {
            lblKeyInserted.text = "This device or OS does not support a YubiKey."
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            // Disable state observation (see LightningInteractionViewController)
            observeSessionStateUpdates = false
            YubiKitManager.shared.keySession.cancelCommands()
        }
    }
    
    private func updateKeyInfo() {
        let state = YubiKitManager.shared.keySession.sessionState
        if (state == .opening) {
            lblKeyInserted.text = "Opening connection to YubiKey"
            
        }
        if (state == .open) {
            guard let keyDescription = YubiKitManager.shared.keySession.keyDescription else {
                return
            }
            lblKeyInserted.text = "\(keyDescription.name) CONNECTED"
            lblKeyInserted.textColor = hexStringToUIColor(hex: "#9aca3c")
            lblFirmware.text = "Firmware: \(keyDescription.firmwareRevision)"
            lblSerial.text = "Serial: \(keyDescription.serialNumber)"
        }
        else // closing or closed
        {
            lblKeyInserted.text = "YubiKey NOT CONNECTED"
            lblKeyInserted.textColor = UIColor.red
            lblFirmware.text = ""
            lblSerial.text = ""
            return
        }
    }
    
    // MARK: - State Observation
    
    override func keySessionStateDidChange() {
        let state = YubiKitManager.shared.keySession.sessionState
        
        if state == .closed {
            //presentLightningActionSheet(state: .insertKey, message: "Insert your YubiKey into the Lightning port.")
        }
        if state == .open {
            //dismissLightningActionSheet()
        }
        updateKeyInfo()
    }
    
    private func presentLightningActionSheetOnMain(state: LightningInteractionViewControllerState, message: String) {
        dispatchMain { [weak self] in
            self?.presentLightningActionSheet(state: state, message: message)
        }
    }
    
    private func dispatchMain(execute: @escaping ()->Void) {
        if Thread.isMainThread {
            execute()
        } else {
            DispatchQueue.main.async(execute: execute)
        }
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

