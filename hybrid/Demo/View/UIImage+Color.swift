//
//  UIImage+Color.swift
//  hybrid
//
//  Created by roylee on 2020/12/9.
//  Copyright © 2020 bantang. All rights reserved.
//

import UIKit

extension UIImage {
    func filled(color: UIColor?) -> UIImage? {
        guard let color = color else {
            return self
        }
        
        /// Begin a new image context, to draw our colored image onto with the right scale
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)

        /// Get a reference to that context we created
        let context = UIGraphicsGetCurrentContext()

        /// Set the fill color
        color.setFill()
        
        /// Translate/flip the graphics context (for transforming from CG* coords to UI* coords
        context?.translateBy(x: 0, y: size.height)
        context?.scaleBy(x: 1, y: -1)
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context?.setBlendMode(.colorBurn)
        guard let cgImage = cgImage else {
            return nil
        }
        context?.draw(cgImage, in: rect)
        
        context?.setBlendMode(.sourceIn)
        context?.addRect(rect)
        context?.drawPath(using: .fill)

        /// Generate a new UIImage from the graphics context we drew onto
        let filledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        /// Return the color-burned image
        return filledImage
    }
}
