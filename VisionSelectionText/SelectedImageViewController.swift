//
//  SelectedImageViewController.swift
//  VisionSelectionText
//
//  Created by Andrew on 2018-04-27.
//  Copyright © 2018 Andrew. All rights reserved.
//

import UIKit
import Photos
import Vision

class SelectedImageViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    var imagePicked:UIImage?
    private var debug = false
    private var tessResult:String?
    private var box3:CGRect?
    private var box2:CGRect?
    private var requests = [VNRequest]()
    private let session = AVCaptureSession()
    private var orientation : AVCaptureVideoOrientation = .portrait
    let overlay = UIView()
    var lastPoint =  CGPoint(x: 0, y: 0)
    var flag = false
    var initialImage:UIImage?
    @IBOutlet weak var previewView: PreviewView!
    var imageview:UIImageView?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = (self as UIImagePickerControllerDelegate & UINavigationControllerDelegate)
            imagePicker.sourceType = .photoLibrary;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
            
            
            
        }
        
        
        // Do any additional setup after loading the view.
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            imagePicked = image
           
            let image = UIImage.init(cgImage: image.cgImage!)
            let imageView = UIImageView(image: image)
             imageview = UIImageView(image: image)
            imageView.frame = self.view.bounds.standardized
            self.view.addSubview(imageView)
            
            dismiss(animated:true,completion: nil)
            overlay.layer.borderColor = UIColor.blue.cgColor
            overlay.backgroundColor = UIColor.green.withAlphaComponent(0.5)
            overlay.isHidden = true
            self.view.addSubview(overlay)
            
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        var tyNorm:Float = 0.0
        var txNorm:Float = 0.0
        var fxNorm:Float = 0.0
        var fyNorm:Float = 0.0
        var resolutionX:Float = 0.0
        var resolutionY:Float = 0.0
        var y:Float = 0.0
        var x:Float = 0.0
        var height:Float = 0.0
        var width:Float = 0.0
        
        switch  orientation{
        case .landscapeLeft ,.landscapeRight:
            resolutionX = 1920.0
            resolutionY = 1080.0
            tyNorm = Float(ty).normalize(min: 0.0, max: 1024.0) * resolutionY
            txNorm = Float(tx).normalize(min: 0.0, max: 1366.0) * resolutionX
            fxNorm = Float(fx).normalize(min: 0.0, max: 1366.0) * resolutionX
            fyNorm = Float(fy).normalize(min: 0.0, max: 1024.0) * resolutionY
            y = Float(min(fy,ty)).normalize(min: 0.0, max: 1024.0) * resolutionY
            x =  Float(min(fx,tx)).normalize(min: 0.0, max: 1366.0) * resolutionX
            height = fabs(fyNorm - tyNorm)
            width = fabs(fxNorm - txNorm)
        case .portraitUpsideDown, .portrait:
            resolutionY = 1920.0
            resolutionX = 1080.0
            tyNorm = Float(ty).normalize(min: 0.0, max: 1366.0) * resolutionY
            txNorm = Float(tx).normalize(min: 0.0, max: 1024.0) * resolutionX
            fxNorm = Float(fx).normalize(min: 0.0, max: 1024.0) * resolutionX
            fyNorm =  Float(fy).normalize(min: 0.0, max: 1366.0) * resolutionY
            x = Float(min(fx,tx)).normalize( min: 0.0, max: 1024.0) * resolutionX
            y =  Float(min(fy,ty)).normalize(min: 0.0, max: 1366.0) * resolutionY
            width = fabs(fxNorm - txNorm)
            height = fabs(fyNorm - tyNorm)
        }
        
        // adjusted for 1920 * 1080 and 1080 * 1920 resolution
        let rect2 = CGRect(x: CGFloat(x),
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
        
//        print(previewView.frame)
        print(overlay.frame)
        
        
        
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        overlay.isHidden = true
        
        
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.textDetectionHandler )
        textRequest.reportCharacterBoxes = true
        self.requests = [textRequest]
        var requestOptions:[VNImageOption : Any] = [:]
        let initialImage2 =  UIImage(cgImage:  (imageview?.image?.cgImage!.cropping(to: box3!))!)
        let imageRequestHandler = VNImageRequestHandler(cgImage: initialImage2.cgImage!, options: requestOptions)
        //        if(debug){
//            print(initialImage?.imageOrientation.rawValue as Any)
//            print(connection.videoOrientation.rawValue)
//            print(previewView.videoPreviewLayer.connection?.videoOrientation.rawValue as Any)
//        }
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
        //        overlay.frame = CGRect(x: 0, y: 0, width: 0, height: 0)//reset overlay for next tap
        flag = true
    }
    
    
    
    func checkPermission() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized:
            print("Access is granted by user")
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({
                (newStatus) in
                print("status is \(newStatus)")
                if newStatus ==  PHAuthorizationStatus.authorized {
                    /* do stuff here */
                    print("success")
                }
            })
            print("It is not determined until now")
        case .restricted:
            // same same
            print("User do not have access to photo album.")
        case .denied:
            // same same
            print("User has denied the permission.")
        }
    }
    
    func textDetectionHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results else {print("no result"); return}
        
        let result = observations.map({$0 as? VNTextObservation})
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
        
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.blue.cgColor
        
        previewView.layer.addSublayer(layer)
    }
    
    
    
    
}
