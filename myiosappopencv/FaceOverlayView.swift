//
//  FaceOverlayView.swift
//  myiosappopencv
//
//  Created by Student on 09/06/24.
//

import UIKit

class FaceOverlayView: UIView {
    private var faceRects: [CGRect] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = .clear
    }

    func setFaces(_ faces: [CGRect]) {
        self.faceRects = faces
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(2.0)
        
        for face in faceRects {
            context.stroke(face)
        }
    }
}
