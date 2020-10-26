//  Created by Matthias Schlemm on 05/03/15.
//  Copyright (c) 2015 Sixpolys. All rights reserved.
//  Licensed under the MIT License.
//  URL: https://github.com/MrMatthias/SwiftColorPicker

import UIKit
import CoreGraphics

@IBDesignable open class HuePicker: UIView {
    
    var _h: CGFloat = 0.1111
    open var h: CGFloat { // [0,1]
        
        set(value) {
            
            _h = min(1, max(0, value))
            currentPoint = CGPoint(x: CGFloat(_h), y: 0)
            setNeedsDisplay()
        }
        
        get {
            return _h
        }
    }
    var image: UIImage?
    fileprivate var data: [UInt8]?
    fileprivate var currentPoint = CGPoint.zero
    open var handleColor: UIColor = UIColor.black
    
    open var onHueChange:((_ hue:CGFloat, _ finished:Bool) -> Void)?
    
    open func setHueFromColor(_ color:UIColor) {
        var h:CGFloat = 0
        color.getHue(&h, saturation: nil, brightness: nil, alpha: nil)
        self.h = h
    }
    
    public override init(frame: CGRect) {
        
        super.init(frame: frame)
        isUserInteractionEnabled = true
    }

    public required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        isUserInteractionEnabled = true
        
        // p add border
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.black.cgColor
    }
    
    
    func renderBitmap() {
        
        if bounds.isEmpty {
            return
        }
        
        let width = UInt(bounds.width)
        let height = UInt(bounds.height)
        
        if  data == nil {
            data = [UInt8](repeating: UInt8(255), count: Int(width * height) * 4)
        }

        var p = 0.0
        var q = 0.0
        var t = 0.0

        var i = 0
        //_ = 255
        var double_v:Double = 0
        var double_s:Double = 0
        let widthRatio:Double = 360 / Double(bounds.width)
        var d = data!
        for hi in 0..<Int(bounds.width) {
            
            let double_h: Double = widthRatio * Double(hi) / 60
            let sector: Int = Int(floor(double_h))
            let f: Double = double_h - Double(sector)
            let f1: Double = 1.0 - f
            double_v = Double(1)
            double_s = Double(1)
            p = double_v * (1.0 - double_s) * 255
            q = double_v * (1.0 - double_s * f) * 255
            t = double_v * ( 1.0 - double_s  * f1) * 255
            let v255 = double_v * 255
            i = hi * 4
            switch(sector) {
            case 0:
                d[i+1] = UInt8(v255)
                d[i+2] = UInt8(t)
                d[i+3] = UInt8(p)
            case 1:
                d[i+1] = UInt8(q)
                d[i+2] = UInt8(v255)
                d[i+3] = UInt8(p)
            case 2:
                d[i+1] = UInt8(p)
                d[i+2] = UInt8(v255)
                d[i+3] = UInt8(t)
            case 3:
                d[i+1] = UInt8(p)
                d[i+2] = UInt8(q)
                d[i+3] = UInt8(v255)
            case 4:
                d[i+1] = UInt8(t)
                d[i+2] = UInt8(p)
                d[i+3] = UInt8(v255)
            default:
                d[i+1] = UInt8(v255)
                d[i+2] = UInt8(p)
                d[i+3] = UInt8(q)
            }
        }
        var sourcei = 0
        for v in 1..<Int(bounds.height) {
            for s in 0..<Int(bounds.width) {
                sourcei = s * 4
                i = (v * Int(width) * 4) + sourcei
                d[i+1] = d[sourcei+1]
                d[i+2] = d[sourcei+2]
                d[i+3] = d[sourcei+3]
            }
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)

        let provider = CGDataProvider(data: Data(bytes: d, count: d.count * MemoryLayout<UInt8>.size) as CFData)
        let cgimg = CGImage(width: Int(width), height: Int(height), bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: Int(width) * Int(MemoryLayout<UInt8>.size * 4),
            space: colorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        
        
        self.image = UIImage(cgImage: cgimg!)
    }
    
    fileprivate func handleTouch(_ touch: UITouch, finished: Bool) {
        
        let point = touch.location(in: self)
        currentPoint = CGPoint(x: max(0, min(bounds.width, point.x)) / bounds.width , y: 0)
        _h = currentPoint.x
        onHueChange?(h, finished)
        setNeedsDisplay()
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches.first! as UITouch, finished: false)
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches.first! as UITouch, finished: false)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches.first! as UITouch, finished: true)
    }
    
    
    override open func draw(_ rect: CGRect) {
        
        if image == nil {
            renderBitmap()
        }
        if let img = image {
            img.draw(in: rect)
        }

        let handleRect = CGRect(x: bounds.width * currentPoint.x - /*:3*/5, y: 0,
                                width: 6, height: bounds.height)
        drawHueDragHandler(frame: handleRect)
    }
    
    func drawHueDragHandler(frame: CGRect) {
        
        // p General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        // p Shadow Declarations
        let shadow = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor
        let shadowOffset = CGSize(width: 3.1, height: 3.1)
        let shadowBlurRadius: CGFloat = 3
        // p Set context state
        context.saveGState()
        context.setShadow(offset: shadowOffset, blur: shadowBlurRadius, color: shadow)
        
        
        // Polygon Drawing - upper handle
        let polygonPath = UIBezierPath()
        polygonPath.move(to: CGPoint(x: frame.minX + 4, y: frame.maxY - 13))
        polygonPath.addLine(to: CGPoint(x: frame.minX + 4, y: frame.maxY))
        polygonPath.addLine(to: CGPoint(x: frame.minX + 6, y: frame.maxY))
        polygonPath.addLine(to: CGPoint(x: frame.minX + 6, y: frame.maxY - 13))
        polygonPath.close()
        UIColor.white.setFill()
        polygonPath.fill()
        
        // Polygon 2 Drawing - lower handle
        let polygon2Path = UIBezierPath()
        polygon2Path.move(to: CGPoint(x: frame.minX + 4, y: frame.minY + 13))
        polygon2Path.addLine(to: CGPoint(x: frame.minX + 4, y: frame.minY))
        polygon2Path.addLine(to: CGPoint(x: frame.minX + 6, y: frame.minY))
        polygon2Path.addLine(to: CGPoint(x: frame.minX + 6, y: frame.minY + 13))
        polygon2Path.close()
        UIColor.white.setFill()
        polygon2Path.fill()
        
        
        // p Restore context state
        context.restoreGState()
    }
}

