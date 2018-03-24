//
//  ViewController.swift
//  VisionSelectionText
//
//  Created by Andrew on 2018-03-24.
//  Copyright © 2018 Andrew. All rights reserved.
//


import UIKit
import Vision
import AVFoundation

class VisionSelectionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var debug = false
    private var boxb:CGRect?
    private var box2:CGRect?
    private var requests = [VNRequest]()
    private let session = AVCaptureSession()
    var rot : CGAffineTransform?
    private var orientation : AVCaptureVideoOrientation = .portrait
    let overlay = UIView()
    var lastPoint =  CGPoint(x: 0, y: 0)
    
    
    var initialImage:UIImage?
    @IBOutlet weak var previewView: PreviewView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        previewView.layer.borderColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        //        previewView.layer.borderWidth = 4
//        previewView
        overlay.layer.borderColor = UIColor.blue.cgColor
        overlay.backgroundColor = UIColor.green.withAlphaComponent(0.5)
        overlay.isHidden = true
        self.view.addSubview(overlay)
        setupCamera()
        //        setupVision()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //Save original tap Point
        if let touch = touches.first {
            lastPoint = touch.location(in: self.view)
        }
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        //Get the current known point and redraw
        if let touch = touches.first {
            let currentPoint = touch.location(in: self.view)
            reDrawSelectionArea(fromPoint: lastPoint, toPoint: currentPoint)
        }
    }
    
    func reDrawSelectionArea(fromPoint: CGPoint, toPoint: CGPoint) {
        overlay.isHidden = false
        
        //Calculate rect from the original point and last known point
        let rect = CGRect(x: min(fromPoint.x, toPoint.x),
                          y: min(fromPoint.y, toPoint.y),
                          width : fabs(fromPoint.x - toPoint.x),
                          height: fabs(fromPoint.y - toPoint.y))
        
        overlay.frame = rect
        
        box2 = rect
        
        
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        overlay.isHidden = true
        
        if (debug){
            print("this is your final box size \(String(describing: boxb?.debugDescription))")
            print("this is your final box size \(String(describing: box2?.debugDescription))")
            print("video preview layer size \(previewView.videoPreviewLayer.frame.width)")
            print("video preview layer size \(previewView.videoPreviewLayer.frame.height)")
            print("overlay layer size \(overlay.frame.width)")
            print("overlay layer size \(overlay.frame.height)")
        }
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.textDetectionHandler )
        textRequest.reportCharacterBoxes = true
        self.requests = [textRequest]
        
        
        overlay.frame = CGRect(x: 0, y: 0, width: 0, height: 0)//reset overlay for next tap
    }
    /* BELOW IS ALL VSION REALTED FUNCTIONS
     #######################################
     ########################################
     #######################################
     */
    
    
    
    
    private func videoOrientationFromCurrentDeviceOrientation() -> AVCaptureVideoOrientation {
        switch UIApplication.shared.statusBarOrientation {
        case .portrait:
            return AVCaptureVideoOrientation.portrait
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeRight
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        default:
            return AVCaptureVideoOrientation.portrait
        }
    }
    
    private func videoOrientationFromCurrentDeviceOrientationw() -> AVCaptureVideoOrientation {
        switch UIApplication.shared.statusBarOrientation {
        case .portrait:
            return AVCaptureVideoOrientation.portrait
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeRight
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        default:
            return AVCaptureVideoOrientation.portrait
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate(alongsideTransition: { [weak self] (context) -> Void in
            self?.previewView?.videoPreviewLayer.connection?.videoOrientation = (self?.videoOrientationFromCurrentDeviceOrientation())!
            self?.previewView.videoPreviewLayer.frame.size = size
            
            
            },completion: { (context) -> Void in
                
        })
        
        super.viewWillTransition(to: size, with: coordinator)
    }
    override func viewDidLayoutSubviews() {
        orientation = transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
        
    }
    
    // MARK: - Vision Setup
    func setupVision() {
        //        print("heree")
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.textDetectionHandler )
        textRequest.reportCharacterBoxes = true
        
        
        
        self.requests = [textRequest]
    }
    
    func textDetectionHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results else {print("no result"); return}
        
        let result = observations.map({$0 as? VNTextObservation})
        //        result[0]!.characterBoxes
        DispatchQueue.main.async() {[weak self] in
            self?.previewView.layer.sublayers?.removeSubrange(1...)
            for region in result {
                guard let rg = region else {continue}
                self?.drawRegionBox(box: rg)
                if let boxes = region?.characterBoxes {
                    for characterBox in boxes {
                        //                        print(characterBox)
                        //                        break
                        //                        characterBox
                        self?.drawTextBox(box: characterBox)
                    }
                }
            }
        }
    }
    
    // MARK: - Draw
    func drawRegionBox(box: VNTextObservation) {
        //        print(box.characterBoxes)
        guard let boxes = box.characterBoxes else {return}
        
        var xMin: CGFloat = 9999.0
        var xMax: CGFloat = 0.0
        var yMin: CGFloat = 9999.0
        var yMax: CGFloat = 0.0
        
        
        for char in boxes {
            
            if char.bottomLeft.x < xMin {xMin = char.bottomLeft.x}
            if char.bottomRight.x > xMax {xMax = char.bottomRight.x}
            if char.bottomRight.y < yMin {yMin = char.bottomRight.y}
            if char.topRight.y > yMax {yMax = char.topRight.y}
        }
        
        let xCoord = xMin * previewView.frame.size.width
        let yCoord = (1 - yMax) * previewView.frame.size.height
        let width = (xMax - xMin) * previewView.frame.size.width
        let height = (yMax - yMin) * previewView.frame.size.height
        
        let layer = CALayer()
        
        
        layer.frame = CGRect(x: xCoord, y: yCoord, width: width, height: height)
        let wordRect = CGRect(x: xCoord, y: yCoord, width: width, height: height)
        guard box2!.contains(wordRect.origin) else { return }
        layer.frame.applying(rot ?? CGAffineTransform.identity)
        layer.borderWidth = 2.0
        layer.borderColor = UIColor.green.cgColor
        
        let fromRect=layer.frame
        let drawImage = initialImage!.cgImage!.cropping(to: fromRect)
        if let imageTObe = drawImage{
            let bimage = UIImage(cgImage: imageTObe, scale: 1, orientation: .right)
        }
        
        
        
        //        image.image=bimage
        
        
        previewView.layer.addSublayer(layer)
    }
    
    func drawTextBox(box: VNRectangleObservation) {
        let xCoord = box.topLeft.x * previewView.frame.size.width
        let yCoord = (1 - box.topLeft.y) * previewView.frame.size.height
        let width = (box.topRight.x - box.bottomLeft.x) * previewView.frame.size.width
        let height = (box.topLeft.y - box.bottomLeft.y) * previewView.frame.size.height
        
        let layer = CALayer()
        layer.frame = CGRect(x: xCoord, y: yCoord, width: width, height: height)
        let wordRect = CGRect(x: xCoord, y: yCoord, width: width, height: height)
        guard box2!.contains(wordRect.origin) else { return }
        layer.frame.applying(rot ?? CGAffineTransform.identity)
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.blue.cgColor
        
        previewView.layer.addSublayer(layer)
    }
    
    
    // MARK: - Camera Delegate and Setup
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //        var or = CGImagePropertyOrientation(rawValue: 6)!
        
        switch  orientation{
        case .landscapeLeft:
            connection.videoOrientation =  .portrait
        case .landscapeRight:
            connection.videoOrientation =  .portraitUpsideDown
        case .portraitUpsideDown:
            connection.videoOrientation =  .landscapeLeft
        case .portrait:
            connection.videoOrientation =  .landscapeRight
            
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        
        
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
        //        print(imageRequestHandler)
        
        let context = CIContext(options: nil)
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { fatalError("cg image") }
        initialImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right )
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    func setupCamera() {
        previewView.session = session
        let availableCameraDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        
        var activeDevice: AVCaptureDevice?
        
        
        for device in availableCameraDevices.devices as [AVCaptureDevice]{
            if device.position == .back {
                activeDevice = device
                
                break
            }
        }
        
        do {
            let camInput = try AVCaptureDeviceInput(device: activeDevice!)
            
            if session.canAddInput(camInput) {
                session.addInput(camInput)
            }
        } catch {
            print("no camera")
        }
        //        session.sessionPreset = .high
        session.sessionPreset = .hd1920x1080
        guard auth() else {return}
        
        let videoOutput = AVCaptureVideoDataOutput()
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "buffer queue", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil))
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        previewView.videoPreviewLayer.videoGravity = .resize
        
        previewView.videoPreviewLayer.connection?.videoOrientation = transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
        //
        //        myView.layer.addSublayer(prevLayer)
        
        session.startRunning()
    }
    
    private func auth() -> Bool{
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video,
                                          completionHandler: { (granted:Bool) in
                                            if granted {
                                                DispatchQueue.main.async {
                                                    self.previewView.setNeedsDisplay()
                                                }
                                            }
            })
            return true
        case .authorized:
            return true
        case .denied, .restricted: return false
        }
    }
    
    func transformOrientation(orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        //4
        case .landscapeLeft:
            return .landscapeLeft
        //3
        case .landscapeRight:
            return .landscapeRight
        //2
        case .portraitUpsideDown:
            //1
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
}


