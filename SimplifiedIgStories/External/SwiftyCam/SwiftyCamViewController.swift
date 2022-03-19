 /*Copyright (c) 2016, Andrew Walz.

Redistribution and use in source and binary forms, with or without modification,are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit
import AVFoundation
import Combine

// MARK: View Controller Declaration

/// A UIViewController Camera View Subclass
open class SwiftyCamViewController: UIViewController {

	// MARK: Enumeration Declaration

	/// Enumeration for Camera Selection
    public enum CameraSelection: String {
        /// Camera on the back of the device
        case rear = "rear"
        
        /// Camera on the front of the device
        case front = "front"
        
        var captureDevicePosition: AVCaptureDevice.Position {
            switch self {
            case .rear:
                return .back
            case .front:
                return .front
            }
        }
    }
    
    public enum FlashMode {
        case auto, on, off
        
        // Return the equivalent AVCaptureDevice.FlashMode
        var AVFlashMode: AVCaptureDevice.FlashMode {
            switch self {
            case .on:
                return .on
            case .off:
                return .off
            case .auto:
                return .auto
            }
        }
    }

	/**
	Result from the AVCaptureSession Setup
	- success: success
	- notAuthorized: User denied access to Camera of Microphone
	- configurationFailed: Unknown error
	*/

	fileprivate enum SessionSetupResult {
		case success
		case notAuthorized
		case configurationFailed
	}

	// MARK: Public Variable Declarations

	/// Maxiumum video duration if SwiftyCamButton is used
    public var maximumVideoDuration: Double = 0.0
    
    /// Video capture quality
    public var videoQuality: AVCaptureSession.Preset = .high
    
    // Flash Mode
    public var flashMode: FlashMode = .off

	/// Sets whether Pinch to Zoom is enabled for the capture session
	public var pinchToZoom = true

	/// Sets the maximum zoom scale allowed during gestures gesture
	public var maxZoomScale = CGFloat.greatestFiniteMagnitude

	/// Sets whether Tap to Focus and Tap to Adjust Exposure is enabled for the capture session
	public var tapToFocus = true

	/// Sets whether the capture session should adjust to low light conditions automatically
	/// Only supported on iPhone 5 and 5C
	public var lowLightBoost = true

	/// Set whether SwiftyCam should allow background audio from other applications
	public var allowBackgroundAudio = true

	/// Sets whether a double tap to switch cameras is supported
	public var doubleTapCameraSwitch = true

    /// Sets whether swipe vertically to zoom is supported

    public var swipeToZoom = true

    /// Sets whether swipe vertically gestures should be inverted
    public var swipeToZoomInverted = false

	/// Set default launch camera
	public var defaultCamera = CameraSelection.rear

	/// Sets wether the taken photo or video should be oriented according to the device orientation
    public var shouldUseDeviceOrientation = false {
        didSet {
            orientation.shouldUseDeviceOrientation = shouldUseDeviceOrientation
        }
    }

    /// Sets whether or not View Controller supports auto rotation
    public var allowAutoRotate = false

    /// Specifies the [videoGravity](https://developer.apple.com/reference/avfoundation/avcapturevideopreviewlayer/1386708-videogravity) for the preview layer.
    public var videoGravity: SwiftyCamVideoGravity = .resizeAspect

    /// Sets whether or not video recordings will record audio
    /// Setting to true will prompt user for access to microphone on View Controller launch.
    public var audioEnabled = true

    /// Sets whether or not app should display prompt to app settings if audio/video permission is denied
    /// If set to false, delegate function will be called to handle exception
    public var shouldPrompToAppSettings = true

    /// Video will be recorded to this folder
    public var outputFolder: String = NSTemporaryDirectory()
    
    // MARK: Public Get-only Variable Declarations
    
    /// Public access to Pinch Gesture
    fileprivate(set) public var pinchGesture: UIPinchGestureRecognizer!

    /// Public access to Pan Gesture
    fileprivate(set) public var panGesture: UIPanGestureRecognizer!

	/// Returns true if video is currently being recorded
	private(set) public var isVideoRecording = false

	/// Returns true if the capture session is currently running
	private(set) public var isSessionRunning = false

	/// Returns the CameraSelection corresponding to the currently utilized camera
	private(set) public var currentCamera = CameraSelection.rear

	// MARK: Private Constant Declarations

	/// Current Capture Session
	public let session = AVCaptureSession()

	/// Serial queue used for setting up session
	fileprivate let sessionQueue = DispatchQueue(label: "session queue")

	// MARK: Private Variable Declarations

	/// Variable for storing current zoom scale
	fileprivate var zoomScale = CGFloat(1.0)

	/// Variable for storing initial zoom scale before Pinch to Zoom begins
	fileprivate var beginZoomScale = CGFloat(1.0)

	/// Returns true if the torch (flash) is currently enabled
	fileprivate var isCameraTorchOn = false

	/// Variable to store result of capture session setup
	fileprivate var setupResult = SessionSetupResult.success

	/// BackgroundID variable for video recording
	fileprivate var backgroundRecordingID: UIBackgroundTaskIdentifier?

	/// Video Input variable
	fileprivate var videoDeviceInput: AVCaptureDeviceInput!

	/// Movie File Output variable
	fileprivate var movieFileOutput: AVCaptureMovieFileOutput?

	/// Photo File Output variable
	fileprivate var photoFileOutput: AVCapturePhotoOutput?

	/// Video Device variable
	fileprivate var videoDevice: AVCaptureDevice?

	/// PreviewView for the capture session
	fileprivate var previewLayer: PreviewView!

	/// UIView for front facing flash
	fileprivate var flashView: UIView?

    /// Pan Translation
    fileprivate var previousPanTranslation: CGFloat = 0.0

	/// Last changed orientation
    fileprivate var orientation: Orientation = Orientation()

    /// Boolean to store when View Controller is notified session is running
    fileprivate var sessionRunning = false

	/// Disable view autorotation for forced portrait recorindg
	override open var shouldAutorotate: Bool {
		return allowAutoRotate
	}

	/// Sets output video codec
    public var videoCodecType: AVVideoCodecType = .h264
    
    // Combine framework variables
    /// Get rid of delegate approach, use publisher approach.
    /// Wanna keep the publisher alived, no ERROR TYPE will be emitted,
    /// all errors are included to SwiftyCamStatus.
    private let publisher = PassthroughSubject<SwiftyCamStatus, Never>()
    
    private var subscriptions = Set<AnyCancellable>()

	// MARK: ViewDidLoad

	/// ViewDidLoad Implementation
	override open func viewDidLoad() {
		super.viewDidLoad()
        
        previewLayer = PreviewView(frame: view.frame, videoGravity: videoGravity)
        previewLayer.center = view.center
        view.addSubview(previewLayer)
        view.sendSubviewToBack(previewLayer)

		// Add Gesture Recognizers
        addGestureRecognizers()

		previewLayer.session = session

		// Test authorization status for Camera and Micophone
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized: // already authorized
            break
        case .notDetermined: // not yet determined
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            }
        default: // already been asked. Denied access
            setupResult = .notAuthorized
        }
        
		sessionQueue.async { [unowned self] in
			self.configureSession()
		}
        
        subscribeCaptureSessionNotifications()
	}

    // MARK: ViewDidLayoutSubviews

    /// ViewDidLayoutSubviews() Implementation
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard
            let connection = previewLayer?.videoPreviewLayer.connection,
                connection.isVideoOrientationSupported
        else {
            return
        }
        
        let orientation: UIDeviceOrientation = UIDevice.current.orientation
        connection.videoOrientation = shouldAutorotate ? orientation.captureVideoOrientation : .portrait
        previewLayer.frame = view.bounds
    }

	// MARK: ViewDidAppear

	/// ViewDidAppear(_ animated:) Implementation
	override open func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		// Subscribe to device rotation notifications
		if shouldUseDeviceOrientation {
			orientation.start()
		}

		// Set background audio preference
		setBackgroundAudioPreference()

        sessionQueue.async {
            switch self.setupResult {
            case .success:
                // Begin Session
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                
                // Preview layer video orientation can be set only after the connection is created
                DispatchQueue.main.async {
                    self.previewLayer.videoPreviewLayer.connection?.videoOrientation = self.orientation.getPreviewLayerOrientation()
                }
            case .notAuthorized:
                if self.shouldPrompToAppSettings {
                    self.promptToAppSettings()
                } else {
                    self.publisher.send(.notAuthorized)
                }
            case .configurationFailed:
                // Unknown Error
                self.publisher.send(.configureFailure)
            }
        }
	}

	// MARK: ViewDidDisappear

	/// ViewDidDisappear(_ animated:) Implementation
	override open func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

        // TODO: ***
        NotificationCenter.default.removeObserver(self)
        sessionRunning = false

		// If session is running, stop the session
		if isSessionRunning {
			session.stopRunning()
			isSessionRunning = false
		}

		// Disble flash if it is currently enabled
		disableFlash()

		// Unsubscribe from device rotation notifications
		if shouldUseDeviceOrientation {
			orientation.stop()
		}
	}

	// MARK: Public Functions

    func getPublisher() -> AnyPublisher<SwiftyCamStatus, Never> {
        publisher.eraseToAnyPublisher()
    }
    
	/**
	Capture photo from current session
	*/
	public func takePhoto() {
		guard let device = videoDevice, let photoFileOutput = photoFileOutput else {
			return
		}

        let settings: AVCapturePhotoSettings
        if device.hasFlash && flashMode != .off {
            settings = getCapturePhotoSettings(flashMode: flashMode)
        } else {
            if photoFileOutput.isFlashScene {
                settings = getCapturePhotoSettings(flashMode: flashMode)
            } else {
                settings = getCapturePhotoSettings()
            }
		}
        
        photoFileOutput.capturePhoto(with: settings, delegate: self)
	}

	/**
	Begin recording video of current session
	*/
	public func startVideoRecording() {
        guard sessionRunning else {
            print("[SwiftyCam]: Cannot start video recoding. Capture session is not running")
            return
        }
        
		guard let movieFileOutput = self.movieFileOutput else {
            print("[SwiftyCam]: No AVCaptureMovieFileOutput found.")
			return
		}

        if flashMode == .on {
            switch currentCamera {
            case .rear:
                enableFlash()
            case .front:
                flashView = UIView(frame: view.frame)
                flashView?.backgroundColor = UIColor.white
                flashView?.alpha = 0.85
                previewLayer.addSubview(flashView!)
            }
        }

        // Must be fetched before on main thread
        guard let previewOrientation = previewLayer.videoPreviewLayer.connection?.videoOrientation else {
            return
        }

		sessionQueue.async { [unowned self] in
			if !movieFileOutput.isRecording {
				if UIDevice.current.isMultitaskingSupported {
					self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
				}

				// Update the orientation on the movie file output video connection before starting recording.
				let movieFileOutputConnection = self.movieFileOutput?.connection(with: .video)

				// flip video output if front facing camera is selected
				movieFileOutputConnection?.isVideoMirrored = self.currentCamera == .front

				movieFileOutputConnection?.videoOrientation = self.orientation.getVideoOrientation() ?? previewOrientation

				// Start recording to a temporary file.
				let outputFileName = UUID().uuidString
				let outputFilePath = (self.outputFolder as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
				movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
				self.isVideoRecording = true
                
                self.publisher.send(.recordingVideoBegun)
			} else {
				movieFileOutput.stopRecording()
			}
		}
	}

	/**
	Stop video recording video of current session
	*/
	public func stopVideoRecording() {
		if isVideoRecording {
			isVideoRecording = false
            
            if let movieFileOutput = self.movieFileOutput {
                movieFileOutput.stopRecording()
            }
			
			disableFlash()

			if currentCamera == .front && flashMode == .on && flashView != nil {
				UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {
					self.flashView?.alpha = 0.0
				}, completion: { (_) in
					self.flashView?.removeFromSuperview()
				})
			}
            
            publisher.send(.recordingVideoFinished)
		}
	}

	/**
	Switch between front and rear camera
	SwiftyCamViewControllerDelegate function SwiftyCamDidSwitchCameras(camera:  will be return the current camera selection
	*/
	public func switchCamera() {
		guard !isVideoRecording else {
			print("[SwiftyCam]: Switching between cameras while recording video is not supported")
			return
		}

        guard session.isRunning else {
            return
        }

        currentCamera = currentCamera == .front ? .rear : .front
        
		session.stopRunning()
        
		sessionQueue.async { [unowned self] in
			// remove and re-add inputs and outputs
			for input in self.session.inputs {
				self.session.removeInput(input)
			}

			self.addInputs()
            
            self.publisher.send(.cameraSwitched(camera: self.currentCamera))

			self.session.startRunning()
		}

		// If flash is enabled, disable it as the torch is needed for front facing camera
		disableFlash()
	}

	// MARK: Private Functions

    fileprivate func subscribeCaptureSessionNotifications() {
        // Replace to publisher approach notification.
        NotificationCenter
            .default
            .publisher(for: .AVCaptureSessionDidStartRunning, object: nil)
            .sink { [weak self] _ in
                self?.sessionRunning = true
                self?.publisher.send(.sessionStarted)
            }
            .store(in: &subscriptions)

        NotificationCenter
            .default
            .publisher(for: .AVCaptureSessionDidStopRunning, object: nil)
            .sink { [weak self] _ in
                self?.sessionRunning = false
                self?.publisher.send(.sessionStopped)
            }
            .store(in: &subscriptions)
    }
    
	/// Configure session, add inputs and outputs
	fileprivate func configureSession() {
		guard setupResult == .success else {
			return
		}

		// Set default camera
		currentCamera = defaultCamera

		// begin configuring session
		session.beginConfiguration()
		configureVideoPreset()
		addVideoInput()
		addAudioInput()
		configureVideoOutput()
		configurePhotoOutput()

		session.commitConfiguration()
	}

	/// Add inputs after changing camera()
	fileprivate func addInputs() {
		session.beginConfiguration()
		configureVideoPreset()
		addVideoInput()
		addAudioInput()
		session.commitConfiguration()
	}

	// Front facing camera will always be set to .high
	// If set video quality is not supported, quality will be set to .high
	/// Configure image quality preset
	fileprivate func configureVideoPreset() {
		if currentCamera == .front {
            session.sessionPreset = .high
		} else {
            session.sessionPreset = session.canSetSessionPreset(videoQuality) ? videoQuality : .high
		}
	}

	/// Add Video Inputs
	fileprivate func addVideoInput() {
        videoDevice = Self.deviceWithMediaType(.video, position: currentCamera.captureDevicePosition)
        
		if let device = videoDevice {
			do {
				try device.lockForConfiguration()
                
				if device.isFocusModeSupported(.continuousAutoFocus) {
					device.focusMode = .continuousAutoFocus
                    
					if device.isSmoothAutoFocusSupported {
						device.isSmoothAutoFocusEnabled = true
					}
				}

				if device.isExposureModeSupported(.continuousAutoExposure) {
					device.exposureMode = .continuousAutoExposure
				}

				if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
					device.whiteBalanceMode = .continuousAutoWhiteBalance
				}

				if device.isLowLightBoostSupported && lowLightBoost {
					device.automaticallyEnablesLowLightBoostWhenAvailable = true
				}

				device.unlockForConfiguration()
			} catch {
				print("[SwiftyCam]: Error locking configuration")
			}
		}

		do {
            if let videoDevice = videoDevice {
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                if session.canAddInput(videoDeviceInput) {
                    session.addInput(videoDeviceInput)
                    self.videoDeviceInput = videoDeviceInput
                } else {
                    print("[SwiftyCam]: Could not add video device input to the session")
                    setupResult = .configurationFailed
                    session.commitConfiguration()
                    return
                }
            }
		} catch {
            print("[SwiftyCam]: Could not create video device input: \(error.localizedDescription)")
			setupResult = .configurationFailed
			return
		}
	}

	/// Add Audio Inputs
	fileprivate func addAudioInput() {
        guard audioEnabled else { return }
        
		do {
            if let audioDevice = AVCaptureDevice.default(for: .audio){
                let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(audioDeviceInput) {
                    session.addInput(audioDeviceInput)
                } else {
                    print("[SwiftyCam]: Could not add audio device input to the session")
                }
            } else {
                print("[SwiftyCam]: Could not find an audio device")
            }
		} catch {
			print("[SwiftyCam]: Could not create audio device input: \(error)")
		}
	}

	/// Configure Movie Output
	fileprivate func configureVideoOutput() {
		let movieFileOutput = AVCaptureMovieFileOutput()
        
		if session.canAddOutput(movieFileOutput) {
			session.addOutput(movieFileOutput)
            
			if let connection = movieFileOutput.connection(with: .video) {
				if connection.isVideoStabilizationSupported {
					connection.preferredVideoStabilizationMode = .auto
				}

                if movieFileOutput.availableVideoCodecTypes.contains(videoCodecType) {
                    // Use the H.264 codec to encode the video.
                    movieFileOutput.setOutputSettings([AVVideoCodecKey: videoCodecType], for: connection)
                }
			}
            
			self.movieFileOutput = movieFileOutput
		}
	}

	/// Configure Photo Output
	fileprivate func configurePhotoOutput() {
		let photoFileOutput = AVCapturePhotoOutput()
		if session.canAddOutput(photoFileOutput) {
            session.addOutput(photoFileOutput)
            self.photoFileOutput = photoFileOutput
		}
	}

	/**
	Returns a UIImage from Image Data.
	- Parameter imageData: Image Data returned from capturing photo from the capture session.
	- Returns: UIImage from the image data, adjusted for proper orientation.
	*/

	fileprivate func processPhoto(_ imageData: Data) -> UIImage {
		let dataProvider = CGDataProvider(data: imageData as CFData)
		let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)

		// Set proper orientation for photo
		// If camera is currently set to front camera, flip image
		let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: orientation.getImageOrientation(forCamera: currentCamera))

		return image
	}

	/// Handle Denied App Privacy Settings
	fileprivate func promptToAppSettings() {
		// prompt User with UIAlertView
		DispatchQueue.main.async(execute: { [unowned self] in
			let message = NSLocalizedString("AVCam doesn't have permission to use the camera, please change privacy settings", comment: "Alert message when the user has denied access to the camera")
			let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
			alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
			alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"), style: .default, handler: { action in
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(appSettings)
                }
			}))
			self.present(alertController, animated: true, completion: nil)
		})
	}

	/// Get Devices
	fileprivate class func deviceWithMediaType(_ mediaType: AVMediaType, position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: mediaType, position: position)
	}

	/// Enable flash
	fileprivate func enableFlash() {
		if !isCameraTorchOn {
			toggleFlash()
		}
	}

	/// Disable flash
	fileprivate func disableFlash() {
		if isCameraTorchOn {
			toggleFlash()
		}
	}

	/// Toggles between enabling and disabling flash
	fileprivate func toggleFlash() {
        // Flash is not supported for front facing camera
		guard currentCamera == .rear else {
			return
		}
        
        guard let device = AVCaptureDevice.default(for: .video) else {
            print("[SwiftyCam]: No AVCaptureDevice found.")
            return
        }
        
		// Check if device has a flash
		if device.hasTorch {
			do {
				try device.lockForConfiguration()
                if device.torchMode == .on {
                    device.torchMode = .off
                    isCameraTorchOn = false
				} else {
					do {
						try device.setTorchModeOn(level: 1.0)
						isCameraTorchOn = true
					} catch {
						print("[SwiftyCam]: \(error)")
					}
				}
				device.unlockForConfiguration()
			} catch {
				print("[SwiftyCam]: \(error)")
			}
		}
	}

	/// Sets whether SwiftyCam should enable background audio from other applications or sources
	fileprivate func setBackgroundAudioPreference() {
		guard allowBackgroundAudio && audioEnabled else {
			return
        }

		do {
            try AVAudioSession
                .sharedInstance()
                .setCategory(
                    .playAndRecord,
                    mode: .default,
                    options: [.mixWithOthers, .allowBluetooth, .defaultToSpeaker]
                )
            try AVAudioSession.sharedInstance().setActive(true)
			session.automaticallyConfiguresApplicationAudioSession = false
		} catch {
			print("[SwiftyCam]: Failed to set background audio preference")
		}
	}
    
    // AVCapturePhotoSettings cannot be reused!
    fileprivate func getCapturePhotoSettings(flashMode: FlashMode = .off) -> AVCapturePhotoSettings {
        let settings = AVCapturePhotoSettings()
        settings.livePhotoVideoCodecType = .jpeg
        settings.flashMode = flashMode.AVFlashMode
        return settings
    }
}

extension SwiftyCamViewController : SwiftyCamButtonDelegate {
	/// Sets the maximum duration of the SwiftyCamButton
	public func setMaxiumVideoDuration() -> Double {
		return maximumVideoDuration
	}

	/// Set UITapGesture to take photo
	public func buttonWasTapped() {
		takePhoto()
	}

	/// Set UILongPressGesture start to begin video
	public func buttonDidBeginLongPress() {
		startVideoRecording()
	}

	/// Set UILongPressGesture begin to begin end video
	public func buttonDidEndLongPress() {
		stopVideoRecording()
	}

	/// Called if maximum duration is reached
	public func longPressDidReachMaximumDuration() {
		stopVideoRecording()
	}
}

// MARK: AVCaptureFileOutputRecordingDelegate
extension SwiftyCamViewController : AVCaptureFileOutputRecordingDelegate {
	/// Process newly captured video and write it to temporary directory
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let currentBackgroundRecordingID = backgroundRecordingID {
            backgroundRecordingID = UIBackgroundTaskIdentifier.invalid

            if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
            }
        }

        if let currentError = error {
            print("[SwiftyCam]: Movie file finishing error: \(currentError)")
            publisher.send(.recordingVideoFailure(err: currentError))
        } else {
            publisher.send(.processingVideoFinished(videoUrl: outputFileURL))
        }
    }
}

// MARK: UIGestureRecognizer Declarations
extension SwiftyCamViewController {
	/// Handle pinch gesture
	@objc fileprivate func zoomGesture(pinch: UIPinchGestureRecognizer) {
		guard pinchToZoom && currentCamera == .rear else { // ignore pinch
			return
		}
        
		do {
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession.init(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: currentCamera.captureDevicePosition
            )
            let captureDevice = deviceDiscoverySession.devices.first
			try captureDevice?.lockForConfiguration()

			zoomScale = min(maxZoomScale, max(1.0, min(beginZoomScale * pinch.scale,  captureDevice!.activeFormat.videoMaxZoomFactor)))

			captureDevice?.videoZoomFactor = zoomScale

            publisher.send(.zoomLevelChanged(zoomLevel: zoomScale))

			captureDevice?.unlockForConfiguration()
		} catch {
			print("[SwiftyCam]: Error locking configuration")
		}
	}

	/// Handle single tap gesture
	@objc fileprivate func singleTapGesture(tap: UITapGestureRecognizer) {
		guard tapToFocus else { // Ignore taps
			return
		}

		let screenSize = previewLayer!.bounds.size
		let tapPoint = tap.location(in: previewLayer!)
		let x = tapPoint.y / screenSize.height
		let y = 1.0 - tapPoint.x / screenSize.width
		let focusPoint = CGPoint(x: x, y: y)

		if let device = videoDevice {
			do {
				try device.lockForConfiguration()

				if device.isFocusPointOfInterestSupported {
					device.focusPointOfInterest = focusPoint
					device.focusMode = .autoFocus
				}
				device.exposurePointOfInterest = focusPoint
				device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
				device.unlockForConfiguration()
                
                publisher.send(.focused(atPoint: tapPoint))
			} catch {
				// just ignore
			}
		}
	}

	/// Handle double tap gesture
	@objc fileprivate func doubleTapGesture(tap: UITapGestureRecognizer) {
		guard doubleTapCameraSwitch else {
			return
		}
		switchCamera()
	}

    @objc private func panGesture(pan: UIPanGestureRecognizer) {
        guard swipeToZoom && currentCamera == .rear else { // ignore pan
            return
        }
        let currentTranslation = pan.translation(in: view).y
        let translationDifference = currentTranslation - previousPanTranslation

        do {
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession.init(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: currentCamera.captureDevicePosition
            )
            let captureDevice = deviceDiscoverySession.devices.first
            try captureDevice?.lockForConfiguration()

            let currentZoom = captureDevice?.videoZoomFactor ?? 0.0

            if swipeToZoomInverted {
                zoomScale = min(maxZoomScale, max(1.0, min(currentZoom - (translationDifference / 75),  captureDevice!.activeFormat.videoMaxZoomFactor)))
            } else {
                zoomScale = min(maxZoomScale, max(1.0, min(currentZoom + (translationDifference / 75),  captureDevice!.activeFormat.videoMaxZoomFactor)))
            }

            captureDevice?.videoZoomFactor = zoomScale

            publisher.send(.zoomLevelChanged(zoomLevel: zoomScale))

            captureDevice?.unlockForConfiguration()
        } catch {
            print("[SwiftyCam]: Error locking configuration")
        }

        if pan.state == .ended || pan.state == .failed || pan.state == .cancelled {
            previousPanTranslation = 0.0
        } else {
            previousPanTranslation = currentTranslation
        }
    }

	/**
	Add pinch gesture recognizer and double tap gesture recognizer to currentView
	- Parameter view: View to add gesture recognzier
	*/
	fileprivate func addGestureRecognizers() {
		pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(zoomGesture(pinch:)))
		pinchGesture.delegate = self
		previewLayer.addGestureRecognizer(pinchGesture)

		let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapGesture(tap:)))
		singleTapGesture.numberOfTapsRequired = 1
		singleTapGesture.delegate = self
		previewLayer.addGestureRecognizer(singleTapGesture)

		let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapGesture(tap:)))
		doubleTapGesture.numberOfTapsRequired = 2
		doubleTapGesture.delegate = self
		previewLayer.addGestureRecognizer(doubleTapGesture)

        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture(pan:)))
        panGesture.delegate = self
        previewLayer.addGestureRecognizer(panGesture)
	}
}


// MARK: UIGestureRecognizerDelegate
extension SwiftyCamViewController : UIGestureRecognizerDelegate {
	/// Set beginZoomScale when pinch begins
	public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		if gestureRecognizer.isKind(of: UIPinchGestureRecognizer.self) {
			beginZoomScale = zoomScale
		}
		return true
	}
}

// MARK: AVCapturePhotoCaptureDelegate
extension SwiftyCamViewController: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print("[SwiftyCam]: Fail to capture photo: \(String(describing: error))")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("[SwiftyCam]: Fail to convert pixel buffer")
            return
        }
        
        let image = processPhoto(imageData)
        publisher.send(.photoTaken(photo: image))
    }
}

// MARK: UIDeviceOrientation
extension UIDeviceOrientation {
    var captureVideoOrientation: AVCaptureVideoOrientation {
        switch self {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        default:
            return .portrait
        }
    }
}

// MARK: SwiftyCamStatus for publishing
enum SwiftyCamStatus {
    case sessionStarted
    case sessionStopped
    case photoTaken(photo: UIImage)
    case recordingVideoBegun
    case recordingVideoFinished
    case processingVideoFinished(videoUrl: URL)
    case cameraSwitched(camera: SwiftyCamViewController.CameraSelection)
    case focused(atPoint: CGPoint)
    case zoomLevelChanged(zoomLevel: CGFloat)
    case notAuthorized
    case configureFailure
    case recordingVideoFailure(err: Error)
}
