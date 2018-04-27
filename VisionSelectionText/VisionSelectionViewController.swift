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
import TesseractOCR

class VisionSelectionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate,G8TesseractDelegate {
    private var debug = false
    private var box3:CGRect?
    private var box2:CGRect?
    private var requests = [VNRequest]()
    private let session = AVCaptureSession()
    var rot : CGAffineTransform?
    private var orientation : AVCaptureVideoOrientation = .portrait
    let overlay = UIView()
    var lastPoint =  CGPoint(x: 0, y: 0)
    var flag = false
    var initialImage:UIImage?
    @IBOutlet weak var previewView: PreviewView!
    
    func normalize(value:Float,min:Float,max:Float)->Float{
        return abs((value - min) / (max - min))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        flag = false
        overlay.isHidden = false
        let fx = fromPoint.x
        let fy = fromPoint.y
        let tx = toPoint.x
        let ty = toPoint.y
        var  resolutionX:Float = 0.0
        var resolutionY:Float = 0.0
        var y:Float = 0.0
        var x:Float = 0.0
        var height:Float = 0.0
        var width:Float = 0.0
        switch  orientation{
        case .landscapeLeft ,.landscapeRight:
            resolutionX = 1920.0
            resolutionY = 1080.0
            y = normalize(value: Float(min(fy,ty)), min: 0.0, max: 1024.0) * resolutionY
            x =  normalize(value: Float(min(fx,tx)), min: 0.0, max: 1366.0) * resolutionX
            height = normalize(value: Float(fabs(fy - ty)), min: 0.0, max: 1024.0) * resolutionY
            width = normalize(value: Float(fabs(fx - tx)), min: 0.0, max: 1366.0) * resolutionX
        case .portraitUpsideDown, .portrait:
            resolutionY = 1920.0
            resolutionX = 1080.0
            x = normalize(value: Float(min(fx,tx)), min: 0.0, max: 1024.0) * resolutionX
            y =  normalize(value: Float(min(fy,ty)), min: 0.0, max: 1366.0) * resolutionY
            width = normalize(value: Float(fabs(fx - tx)), min: 0.0, max: 1024.0) * resolutionY
            height = normalize(value: Float(fabs(fy - ty)), min: 0.0, max: 1366.0) * resolutionX
        }
        
        
        
        //
        var rect2 = CGRect(x: CGFloat(x),
                           y: CGFloat(y),
                           width : CGFloat(width),
                           height: CGFloat(height))
        
        
        
        //Calculate rect from the original point and last known point
        let rect = CGRect(x: min(fromPoint.x, toPoint.x),
                          y: min(fromPoint.y, toPoint.y),
                          width : fabs(fromPoint.x - toPoint.x),
                          height: fabs(fromPoint.y - toPoint.y))
        
        box2 = rect
        box3 = rect2
        overlay.frame = rect
        
        print(previewView.frame)
        print(overlay.frame)
        
        
        
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        overlay.isHidden = true
        
        if (debug){
            print("this is your final box size \(String(describing: box3?.debugDescription))")
            print("this is your final box size \(String(describing: box2?.debugDescription))")
            print("video preview layer size \(previewView.videoPreviewLayer.frame.width)")
            print("video preview layer size \(previewView.videoPreviewLayer.frame.height)")
            print("overlay layer size \(overlay.frame.width)")
            print("overlay layer size \(overlay.frame.height)")
        }
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.textDetectionHandler )
        textRequest.reportCharacterBoxes = true
        self.requests = [textRequest]
        
        
        //        overlay.frame = CGRect(x: 0, y: 0, width: 0, height: 0)//reset overlay for next tap
        flag = true
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
        //        self.prevLayer?.connection.videoOrientation = self.transformOrientation(UIInterfaceOrientation(rawValue: UIApplication.sharedApplication().statusBarOrientation.rawValue)!)
        //        self.prevLayer?.frame.size = self.myView.frame.size
        coordinator.animate(alongsideTransition: { [weak self] (context) -> Void in
            
            self?.previewView?.videoPreviewLayer.connection?.videoOrientation = self!.transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
            self?.previewView.videoPreviewLayer.frame.size = size
            
            
            
            },completion: { (context) -> Void in
                
        })
        //        print(self.transformOrientation(orientation: UIInterfaceOrientation(rawValue: (UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)?.rawValue)!)!)
        print(" for preview layer in viewwilltran \(self.previewView?.videoPreviewLayer.connection?.videoOrientation.rawValue)")
        super.viewWillTransition(to: size, with: coordinator)
    }
    override func viewDidLayoutSubviews() {
        
        print("before seting orienttion \(orientation.rawValue)")
        orientation = transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
        previewView.videoPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue)!
        print("after seting orienttion \(orientation.rawValue)")
        print(" for preview layer in viewdi layout \(self.previewView?.videoPreviewLayer.connection?.videoOrientation.rawValue)")
        
        
        
    }
    
    // MARK: - Vision Setup
    func setupVision() {
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
                        self?.drawTextBox(box: characterBox)
                    }
                }
            }
        }
    }
    
    // MARK: - Draw
    func drawRegionBox(box: VNTextObservation) {
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
        //        var initialImage2 =  UIImage(cgImage:  (initialImage?.cgImage?.cropping(to: box3!))!)
        //        poop(initialImage2)
        
        
        
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
        if (flag == false){
            return
        }
        //        var or = CGImagePropertyOrientation(rawValue: 6)!
        
        
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        
        
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        var ciImage2 = CIImage(cvPixelBuffer: pixelBuffer)
        switch  orientation{
        case .landscapeLeft ,.landscapeRight:
            break
        case .portraitUpsideDown, .portrait:
            ciImage2 = ciImage2.oriented(forExifOrientation: 6)
        }
        
        
        
        
        
        let context2 = CIContext(options: nil)
        let cgImage2 = context2.createCGImage(ciImage2, from: ciImage2.extent)
        
        
        var initialImagep =  UIImage(cgImage:  cgImage2!)
        print(initialImagep.imageOrientation.rawValue)
        //                 let rotatedImage  = UIImage.init(cgImage: initialImagep.cgImage!).rotated(by: Measurement(value: 90.0, unit: .degrees))
        var initialImage2 =  UIImage(cgImage:  (initialImagep.cgImage!.cropping(to: box3!))!)
        
        print(connection.videoOrientation.rawValue)
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
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue:6 )!, options: requestOptions)
        
        
        //        print(imageRequestHandler)
        
        let context = CIContext(options: nil)
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { fatalError("cg image") }
        initialImage = initialImagep
        var initialImagep2 =  UIImage(cgImage:  cgImage)
        print(initialImage?.imageOrientation.rawValue)
        print(connection.videoOrientation.rawValue)
        print(previewView.videoPreviewLayer.connection?.videoOrientation.rawValue)
        
        let rotatedImage1 = UIImage(cgImage: cgImage )
        //        var initialImage2 =  UIImage(cgImage:  (initialImage?.cgImage?.cropping(to: box3!))!)
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
        flag = false
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
        
        previewView.videoPreviewLayer.connection!.videoOrientation = transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
        print(previewView.videoPreviewLayer.connection!.videoOrientation.rawValue)
        //         prevLayer?.connection.videoOrientation = transformOrientation(UIInterfaceOrientation(rawValue: UIApplication.sharedApplication().statusBarOrientation.rawValue)!)
        //                myView.layer.addSublayer(prevLayer)
        
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
            return .portraitUpsideDown
        //1
        default:
            return .portrait
        }
    }
    
    
    
    
    func progressImageRecognition(for tesseract: G8Tesseract!) {
        print("Recognition Progress \(tesseract.progress) %")
    }
    
    func poop(image:UIImage) {
        if let tess = G8Tesseract(language: "eng") {
            tess.delegate = self
            tess.image = image.g8_blackAndWhite()
            //            tess.image = UIImage(named: "20180314_000149")?.g8_blackAndWhite()
            tess.recognize()
            print(tess.recognizedText)
            
            //            textView.text = tess.recognizedText
            
        }
    }
    
}


