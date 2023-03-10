//
//  Measure.swift
//  TurtleApp-CoreML
//
//  Created by GwakDoyoung on 03/07/2018.
//  Copyright ยฉ 2018 GwakDoyoung. All rights reserved.
//

import UIKit

protocol ๐Delegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int)
}
// Performance Measurement
class ๐ {
    
    var delegate: ๐Delegate?
    
    var index: Int = -1
    var measurements: [Dictionary<String, Double>]
    
    init() {
            let measurement = [
                "start": CACurrentMediaTime(),
                "end": CACurrentMediaTime()
            ]
            measurements = Array<Dictionary<String, Double>>(repeating: measurement, count: 30)
        }
    
    // start
    func ๐ฌ๐() {
        index += 1
        index %= 30
        measurements[index] = [:]
        
        ๐ท(for: index, with: "start")
    }
    
    // stop
    func ๐ฌ๐ค() {
        ๐ท(for: index, with: "end")
        
        let beforeMeasurement = getBeforeMeasurment(for: index)
        let currentMeasurement = measurements[index]
        if let startTime = currentMeasurement["start"],
            let endInferenceTime = currentMeasurement["endInference"],
            let endTime = currentMeasurement["end"],
            let beforeStartTime = beforeMeasurement["start"] {
            delegate?.updateMeasure(inferenceTime: endInferenceTime - startTime,
                                    executionTime: endTime - startTime,
                                    fps: Int(1/(startTime - beforeStartTime)))
        }
        
    }
    
    // labeling with
    func ๐ท(with msg: String? = "") {
        ๐ท(for: index, with: msg)
    }
    
    private func ๐ท(for index: Int, with msg: String? = "") {
        if let message = msg {
            measurements[index][message] = CACurrentMediaTime()
        }
    }
    
    private func getBeforeMeasurment(for index: Int) -> Dictionary<String, Double> {
        return measurements[(index + 30 - 1) % 30]
    }
    
    // log
    func ๐จ() {
        
    }
}

class MeasureLogView: UIView {
    let etimeLabel = UILabel(frame: .zero)
    let fpsLabel = UILabel(frame: .zero)
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
