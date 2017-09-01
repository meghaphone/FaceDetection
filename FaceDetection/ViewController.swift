//
//  ViewController.swift
//  HelloVision
//
//  Created by Meghan Kane on 8/28/17.
//  Copyright © 2017 Meghan Kane. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    var faceBoxViews: [UIView] = []
    let imagePickerController = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePickerController.delegate = self
    }
    
    @IBAction func selectPhoto() {
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func detectFaces(image: UIImage) {
        // 1. Ask
        // - Create a request (VNDetectFaceRectanglesRequest)
        let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: self.handleFaceDetectionResults)
        
        // 2. Machinery
        // - Create a handler (VNImageRequestHandler) that passes in the image
        // - Call perform on VNImageRequestHandler with VNDetectFaceRectanglesRequest
        // - Dispatch to queue that is appropriate to problem
        DispatchQueue.global(qos: .userInitiated).async {
            // convert to image format that Vision understands: CIImage or CGImage
            guard let ciImage = CIImage(image: image) else {
                fatalError("Unable to convert \(image) to CIImage.")
            }
            
            let faceDetectionHandler = VNImageRequestHandler(ciImage: ciImage)
            do {
                try faceDetectionHandler.perform([faceDetectionRequest])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    // 3. Results
    // - With each VNFaceObservation, add a face box view with the observation's bounding box
    // - Make sure to dispatch on the main queue
    private func handleFaceDetectionResults(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let observations = request.results as? [VNFaceObservation] else {
                return
            }
            
            for observation in observations {
                self.addFaceBoxView(faceBoundingBox: observation.boundingBox)
            }
        }
    }
    
    private func addFaceBoxView(faceBoundingBox: CGRect) {
        let faceBoxView = UIView()
        styleFaceBoxView(faceBoxView)
        let boxViewFrame = transformRect(visionRect: faceBoundingBox, imageViewRect: imageView.frame)
        faceBoxView.frame = boxViewFrame
        imageView.addSubview(faceBoxView)
        faceBoxViews.append(faceBoxView)
    }
    
    private func styleFaceBoxView(_ faceBoxView: UIView) {
        faceBoxView.layer.borderColor = UIColor.yellow.cgColor
        faceBoxView.layer.borderWidth = 2
        faceBoxView.backgroundColor = UIColor.clear
    }
    
    private func transformRect(visionRect: CGRect , imageViewRect: CGRect) -> CGRect {
        
        var mappedRect = CGRect()
        mappedRect.size.width = visionRect.size.width * imageViewRect.size.width
        mappedRect.size.height = visionRect.size.height * imageViewRect.size.height
        mappedRect.origin.y = imageViewRect.height - imageViewRect.height * visionRect.origin.y
        mappedRect.origin.y  = mappedRect.origin.y -  mappedRect.size.height
        mappedRect.origin.x =  visionRect.origin.x * imageViewRect.size.width
        
        return mappedRect
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let imageSelected = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.subviews.forEach({ boxView in
                boxView.removeFromSuperview()
            })
            imageView.contentMode = .scaleAspectFit
            imageView.image = imageSelected
            
            // Kick off Vision task with input
            detectFaces(image: imageSelected)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
