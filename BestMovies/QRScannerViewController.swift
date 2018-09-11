//
//  QRScannerViewController.swift
//  BestMovies
//
//  Created by Daniel Merchasin on 06/09/2018
//  Copyright © 2018 Daniel Merchasin. All rights reserved.
//

import UIKit
import AVFoundation

// Screen 4 - QR Code Scanner
class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var session: AVCaptureSession!
    var videoLayer: AVCaptureVideoPreviewLayer!
    
    @IBOutlet weak var imgScannerFrame: UIImageView!
    
    var result: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        let session = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video), let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            handleError()
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            handleError()
            return
        }
            
        let output = AVCaptureMetadataOutput()
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.qr]
                
        } else {
            handleError()
            return
        }
        
        videoLayer = AVCaptureVideoPreviewLayer(session: session)
        videoLayer.frame = view.layer.bounds
        videoLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(videoLayer)
        
        session.startRunning()
        
        view.bringSubview(toFront: imgScannerFrame)
        
    }
    
    private func handleError() {
        displayAlert(title: "Error", message: "QR code scanning is not supported by this device.") { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        session.stopRunning()
        
        // Check if the scanned object is of type "QR" and it has a string value
        guard let metadataObject = metadataObjects.first,
            let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
            readableObject.type == .qr,
            let stringValue = readableObject.stringValue else {
                // Go back to the previous VC without updating the result
                navigationController?.popViewController(animated: true)
                return
        }
        
        // String value exists, update the result and pop the VC
        result = stringValue
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if session?.isRunning == false {
           session.startRunning()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if session?.isRunning == true {
            session.stopRunning()
        }
        
        performSegue(withIdentifier: unwindIdentifier, sender: self)
    }
    
}
