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

//  This class (along with the nib view) was copied from the YubiKit Demo
import UIKit

//
// MARK: - LightningActionSheetView Configuration
//
class LightningActionSheetViewConfiguration {
    
    let presentAnimationDuration = 0.3
    let dismissAnimationDuration = 0.2
    
    let presentAnimationDurationSlow = 0.5
    let dismissAnimationDurationSlow = 0.4
    
    var currentPresentAnimationDuration: TimeInterval {
        get {
            let cores = ProcessInfo.processInfo.processorCount
            return cores >= 4 ? presentAnimationDuration : presentAnimationDurationSlow
        }
    }
    
    var currentDismissAnimationDuration: TimeInterval {
        get {
            let cores = ProcessInfo.processInfo.processorCount
            return cores >= 4 ? dismissAnimationDuration : dismissAnimationDurationSlow
        }
    }
    
    let actionSheetViewFadeViewAlpha: CGFloat = 0.6
    
    let actionSheetViewBottomConstraintConstant: CGFloat = 5.0
    let keyImageViewTopConstraintDisconnectedConstant: CGFloat = 8
    let keyImageViewTopConstraintConnectedConstant: CGFloat = -19
}

//
// MARK: - LightningActionSheetView
//
protocol LightningActionSheetViewDelegate: NSObjectProtocol {
    func lightningActionSheetDidDismiss(_ actionSheet: LightningActionSheetView)
}

class LightningActionSheetView: UIView {
    
    weak var delegate: LightningActionSheetViewDelegate?
    
    private let configuration = LightningActionSheetViewConfiguration()
    private static let viewNibName = String(describing: LightningActionSheetView.self)
    
    private var isPresenting = false
    private var isDismissing = false
    
    // MARK: - Outlets
    
    @IBOutlet var actionSheetBottomConstraint: NSLayoutConstraint!
    @IBOutlet var actionSheetView: UIView!
    
    @IBOutlet var keyImageView: UIImageView!
    @IBOutlet var keyImageViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet var deviceImageView: UIImageView!
    
    @IBOutlet var keyActionContainerView: UIView!
    @IBOutlet var backgroundFadeView: UIView!
    @IBOutlet var borderView: UIView!
    
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var messageLabel: UILabel!
    
    // MARK: - Lifecycle
    
    class func loadViewFromNib() -> LightningActionSheetView? {
        guard let nibs = Bundle.main.loadNibNamed(viewNibName, owner: nil, options: nil) else {
            return nil
        }
        guard let view = nibs.first as? LightningActionSheetView else {
            return nil
        }
        return view
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    private func setupView() {
        if UIDevice.current.ykd_hasHomeButton() {
            deviceImageView.image = UIImage(named: "LASPhone")
        } else {
            deviceImageView.image = UIImage(named: "LASPhoneNew")
        }
        resetState()
    }
    
    // MARK: - Animation States
    
    private func resetState() {
        borderView.backgroundColor = UIColor.white
        messageLabel.text = nil
        
        layer.removeAllAnimations()
        keyImageView.layer.removeAllAnimations()
    }
    
    func animateProcessing(message: String) {
        resetState()
        
        borderView.backgroundColor = UIColor(red:0.46, green:0.84, blue:1.00, alpha:1.0)
        messageLabel.text = message
        
        animateKeyConnected()
        pulsateBorderView(duration: 1.5)
    }
    
    func animateInsertKey(message: String) {
        resetState()
        
        borderView.backgroundColor = UIColor.white
        messageLabel.text = message
        
        animateConnectKey()
    }
    
    func animateKeyInserted(message: String) {
        resetState()
        
        borderView.backgroundColor = UIColor.white
        messageLabel.text = message
        
        animateConnectKey()
    }
    
    func animateTouchKey(message: String) {
        resetState()
        
        borderView.backgroundColor = UIColor(red:0.73, green:0.91, blue:0.31, alpha:1.0)
        messageLabel.text = message
        
        animateKeyConnected()
        pulsateBorderView(duration: 1)
    }
    
    // MARK: - Presentation
    
    func present(animated: Bool, completion: @escaping ()->Void) {
        guard !isPresenting else {
            return
        }
        isPresenting = true
        
        actionSheetBottomConstraint.constant = -(actionSheetBottomConstraint.constant + actionSheetView.frame.size.height)
        backgroundFadeView.alpha = 0
        
        layoutIfNeeded()
        
        actionSheetBottomConstraint.constant = configuration.actionSheetViewBottomConstraintConstant
        
        let options: UIView.AnimationOptions = [.beginFromCurrentState, .curveEaseOut]
        
        UIView.animate(withDuration: configuration.currentPresentAnimationDuration, delay: 0, options:options, animations: { [weak self] in
            guard let self = self else {
                return
            }
            self.layoutIfNeeded()
            self.backgroundFadeView.alpha = self.configuration.actionSheetViewFadeViewAlpha
        }) { [weak self](_) in
            completion()
            self?.isPresenting = false
        }
    }
    
    func dismiss(animated: Bool, delayed: Bool = true, completion: @escaping ()->Void) {
        guard !isDismissing else {
            return
        }
        isDismissing = true
        
        actionSheetBottomConstraint.constant = configuration.actionSheetViewBottomConstraintConstant
        layoutIfNeeded()
        
        actionSheetBottomConstraint.constant = -(actionSheetBottomConstraint.constant + actionSheetView.frame.size.height)
        
        // Small delay to avoid UI flickering when the state is changing very fast.
        let delay = delayed ? 1.0 : 0
        let options: UIView.AnimationOptions = [.beginFromCurrentState, .curveEaseIn]
        
        UIView.animate(withDuration: configuration.currentDismissAnimationDuration, delay: delay, options:options, animations: { [weak self] in
            guard let self = self else {
                return
            }
            self.layoutIfNeeded()
            self.backgroundFadeView.alpha = 0
        }) { [weak self](_) in
            completion()
            self?.isDismissing = false
        }
    }
    
    // MARK: - Animation Helpers
    
    private func animateConnectKey() {
        layoutIfNeeded()
        
        UIView.animateKeyframes(withDuration: 3, delay: 0, options: .repeat, animations: { [weak self] in
            guard let self = self else {
                return
            }
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.2, animations: {
                self.keyImageViewTopConstraint.constant = self.configuration.keyImageViewTopConstraintConnectedConstant
                self.layoutIfNeeded()
            })
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.4, animations: {
                // Pause
            })
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.2, animations: {
                self.keyImageViewTopConstraint.constant = self.configuration.keyImageViewTopConstraintDisconnectedConstant
                self.layoutIfNeeded()
            })
            UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2, animations: {
                // Pause
            })
            }, completion: nil)
    }
    
    private func animateKeyConnected() {
        UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
            guard let self = self else {
                return
            }
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                self.keyImageViewTopConstraint.constant = self.configuration.keyImageViewTopConstraintConnectedConstant
                self.layoutIfNeeded()
            })
            }, completion: nil)
    }
    
    private func pulsateBorderView(duration: TimeInterval) {
        borderView.alpha = 0
        
        UIView.animateKeyframes(withDuration: duration, delay: 0, options: .repeat, animations: { [weak self] in
            guard let self = self else {
                return
            }
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.1, animations: {
                self.borderView.alpha = 1
            })
            UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.8, animations: {
                // Pause
            })
            UIView.addKeyframe(withRelativeStartTime: 0.9, relativeDuration: 0.1, animations: {
                self.borderView.alpha = 0
            })
            }, completion: nil)
    }
    
    // MARK: - Layout updates
    
    func updateInterfaceOrientation(orientation: UIInterfaceOrientation) {
        var rotationAngle: CGFloat = 0
        switch orientation {
        case .unknown:
            fallthrough
        case .portrait:
            break
        case .landscapeLeft:
            rotationAngle = CGFloat(Double.pi / 2)
        case .landscapeRight:
            rotationAngle = CGFloat(-Double.pi / 2)
        case .portraitUpsideDown:
            rotationAngle = CGFloat(Double.pi)
        @unknown default:
            fatalError()
        }
        keyActionContainerView.transform = CGAffineTransform(rotationAngle: rotationAngle)
    }
    
    // MARK: - Actions
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        guard let delegate = delegate else {
            return
        }
        delegate.lightningActionSheetDidDismiss(self)
    }
}

//
// MARK: - Extensions
//
extension UIDevice /* Lightning Action Sheet */ {
    
    func ykd_hasHomeButton() -> Bool {
        if #available(iOS 11.0, *) {
            guard let keyWindow = UIApplication.shared.keyWindow else {
                return true
            }
            return keyWindow.safeAreaInsets.bottom == 0.0
        }
        return true
    }
}
