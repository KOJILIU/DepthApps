//
//  ViewController.swift
//  DepthPrediction-CoreML
//
//  Created by Doyoung Gwak on 20/07/2019.
//  Copyright © 2019 Doyoung Gwak. All rights reserved.
//

import UIKit
import Vision

class StillImageViewController: UIViewController {
    
    // MARK: - UI Properties
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var drawingView: DrawingHeatmapView!
    
    let imagePickerController = UIImagePickerController()
    
    // MARK - Core ML model
    // FCRN(iOS11+), FCRNFP16(iOS11+)
    let estimationModel = FCRN()
    
    // MARK: - Vision Properties
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    
    let postprocessor = HeatmapPostProcessor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup ml model
        setUpModel()
        
        // image picker delegate setup
        imagePickerController.delegate = self
    }

    @IBAction func tapCamera(_ sender: Any) {
        self.present(imagePickerController, animated: true)
    }
    
    // MARK: - Setup Core ML
    func setUpModel() {
        if let visionModel = try? VNCoreMLModel(for: estimationModel.model) {
            self.visionModel = visionModel
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .centerCrop
        } else {
            fatalError()
        }
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension StillImageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage,
            let url = info[.imageURL] as? URL {
            mainImageView.image = image
            self.predict(with: url)
        }
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Inference
extension StillImageViewController {
    // prediction
    func predict(with url: URL) {
        guard let request = request else { fatalError() }
        
        // vision framework configures the input size of image following our model's input configuration automatically
        let handler = VNImageRequestHandler(url: url, options: [:])
        try? handler.perform([request])
    }
    
    // post-processing
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
           let heatmap = observations.first?.featureValue.multiArrayValue {
            drawingView.heatmap = postprocessor.convertTo2DArray(from: heatmap)
        }
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
           let depthmap = observations.first?.featureValue.multiArrayValue {
            let depthval = convertToArray(from: depthmap)
            writeFile(depthval: depthval)
            guard let _ = depthmap.shape[1] as? Int,
                  let _ = depthmap.shape[2] as? Int else {
                return
            }
        }
    }
    
    func convertToArray(from mlMultiArray: MLMultiArray) -> [Float] {
        // Init our output array
        var array: [Float] = []
        // Get length
        let length = mlMultiArray.count
        // Set content of multi array to our out put array
        for i in 0...length - 1 {
            array.append(Float(truncating: mlMultiArray[[0,NSNumber(value: i)]]))
        }
        
        return array
    }
    
    func writeFile(depthval: Array<Float>)
    {
        let fileName = "Stillimage"
        
        let documentDirectoryUrl = try! FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create:true)
        
        let fileUrl = documentDirectoryUrl.appendingPathComponent(fileName).appendingPathExtension("txt")
        print(fileUrl)
        // prints the values
        // print(depthval)
        
        //data to write in file.
        for i in depthval{
                let val = String(describing: i)
                if let handle = try? FileHandle(forWritingTo: fileUrl) {
                    handle.seekToEndOfFile() // moving pointer to the end
                    handle.write(val.data(using: .utf8)!) // adding content
                    handle.closeFile() // closing the file
                }
            }
        }
    }
