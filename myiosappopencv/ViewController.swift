//
//  ViewController.swift
//  myiosappopencv
//
//  Created by Student on 09/06/24.
//

import UIKit
import AVFoundation
import VideoToolbox

class ViewController: UIViewController,AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var previewView : UIView!
    var boxView:UIView!
    
    //Camera Capture requiered properties
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    var previewLayer:AVCaptureVideoPreviewLayer!
    var captureDevice : AVCaptureDevice!
    let session = AVCaptureSession()
    private var faceOverlayView: FaceOverlayView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        guard let w = (myscene as? UIWindowScene) else { return }
//               let screenSize = w.screen.bounds
        
//        if let width = view.window?.windowScene?.screen.bounds.width, let height = view.window?.windowScene?.screen.bounds.height {
//            debugPrint("Width \(width)")
//            debugPrint("Height \(height)")
//            debugPrint("Width \(UIScreen.main.bounds.width)")
        debugPrint("0")
//        if let width = screen()?.bounds.size.width, let height = screen()?.bounds.size.height {
            debugPrint("1")
            previewView = UIView(frame: CGRect(x: 0,
                                               y: 0,
                                               width: UIScreen.main.bounds.size.width,
                                               height: UIScreen.main.bounds.size.height))
            previewView.contentMode = UIView.ContentMode.scaleAspectFit
            view.addSubview(previewView)
            
            boxView = UIView(frame: self.view.frame)
            view.addSubview(boxView)
            
            // Initialize face overlay view
            faceOverlayView = FaceOverlayView(frame: view.bounds)
            view.addSubview(faceOverlayView)
            
            
            setupAVCapture()
//        }
           
//        } else {
//            debugPrint("Nil")
//        }
       
    }
    
    override var shouldAutorotate: Bool {
        if (UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft ||
            UIDevice.current.orientation == UIDeviceOrientation.landscapeRight ||
            UIDevice.current.orientation == UIDeviceOrientation.unknown) {
            return false
        }
        else {
            return true
        }
    }
    
    func setupAVCapture(){
        session.sessionPreset = AVCaptureSession.Preset.vga640x480
        guard let device = AVCaptureDevice
            .default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                     for: .video,
                     position: AVCaptureDevice.Position.back) else {
            return
        }
        captureDevice = device
        beginSession()
    }
    
    func beginSession(){
        var deviceInput: AVCaptureDeviceInput!
        
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            guard deviceInput != nil else {
                print("error: cant get deviceInput")
                return
            }
            
            if self.session.canAddInput(deviceInput){
                self.session.addInput(deviceInput)
            }
            
            videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.alwaysDiscardsLateVideoFrames=true
            videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
            videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue)
            
            if session.canAddOutput(self.videoDataOutput){
                session.addOutput(self.videoDataOutput)
            }
            
            videoDataOutput.connection(with: .video)?.isEnabled = true
            
            previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            
            let rootLayer :CALayer = self.previewView.layer
            rootLayer.masksToBounds=true
            previewLayer.frame = rootLayer.bounds
            rootLayer.addSublayer(self.previewLayer)
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        } catch let error as NSError {
            deviceInput = nil
            print("error: \(error.localizedDescription)")
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return  }
        
        guard let image = UIImage(pixelBuffer: imageBuffer) else {
            return
        }
        detectFaces(in: image)
        //stopCamera()
    }
    
    
    
    func stopCamera(){
        session.stopRunning()
    }
    
    
    private func detectFaces(in image: UIImage) {
        guard let faceRects = OpenCVWrapper.detectFaceRects(in: image) else { return }
        
        DispatchQueue.main.async {
            let viewWidth = self.faceOverlayView.bounds.width
            let viewHeight = self.faceOverlayView.bounds.height
            let imageWidth = image.size.width
            let imageHeight = image.size.height
            
            let scaleX = viewWidth / imageWidth
            let scaleY = viewHeight / imageHeight
            
            let scaleFactor = min(scaleX, scaleY)
            
            let offsetX = (viewWidth - imageWidth * scaleFactor) / 2
            let offsetY = (viewHeight - imageHeight * scaleFactor) / 2
            
            let transformedRects = faceRects.map { $0.cgRectValue }.map { face in
                return CGRect(
                    x: face.origin.x * scaleFactor + offsetX,
                    y: face.origin.y * scaleFactor + offsetY,
                    width: face.size.width * scaleFactor,
                    height: face.size.height * scaleFactor
                )
            }
            
            self.faceOverlayView.setFaces(transformedRects)
        }
    }
    
    
}


extension UIImage {
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        
        guard let cgImage = cgImage else {
            return nil
        }
        
        self.init(cgImage: cgImage)
    }
}

extension UIViewController {
  func screen() -> UIScreen? {
    var parent = self.parent
    var lastParent = parent
    
    while parent != nil {
      lastParent = parent
      parent = parent!.parent
    }
    
    return lastParent?.view.window?.windowScene?.screen
  }
}
