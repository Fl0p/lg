import UIKit
import CoreImage

class LGView: UIView {
    private var dmFilter = DisplacementMapFilter()
    private var ciContext = CIContext()
    private var scaleFactor: Float {
        return Float(self.contentScaleFactor)
    }
    private var halfShortSide: Float {
        return 0.5 * Float(min(bounds.width, bounds.height))
    }
    private var capturedImage: CIImage?
    private var filteredImage: CIImage? = nil {
        didSet {
            guard let fi = filteredImage else {
                self.filteredImageView?.image = nil
                return
            }
            let uiImage = UIImage(ciImage: fi)
            self.filteredImageView?.image = uiImage
        }
    }
    private var filteredImageView: UIImageView?
    private var updateRequired = false
    
    public var displacementMapImage: UIImage? {
        didSet {
            guard let cgImage = displacementMapImage?.cgImage else {
                dmFilter.displacementMap = nil
                return
            }
            dmFilter.displacementMap = LGView.convertColorSpace(image: CIImage(cgImage: cgImage))
        }
    }
    
    
    public var sourceView: UIView?
    
    // in percents of half shotest side 50% by default
    public var radius: Float = 0.5 {
        didSet {
            let cornerRadius: Float = radius * halfShortSide
            dmFilter.radius = scaleFactor * cornerRadius
            triggerUpdate()
        }
    }
    public var scale: Float = 100 {
        didSet {
            dmFilter.scale = scaleFactor * scale
            triggerUpdate()
        }
    }
    
    //relative from 0.0 to 10.0;
    // =1.0 mean full size round besel
    // >1 mean besel only on the edge and center is flat
    // <1 make besel more conic
    public var bezel: Float = DisplacementMapFilter.DefaultValues.bezel {
        didSet {
            dmFilter.bezel = bezel
            triggerUpdate()
        }
    }
    
    // in percents of half shotest side
    public var padding: Float = 0 {
        didSet {
            setNeedsLayout()
            dmFilter.padding = scaleFactor * padding * halfShortSide
            triggerUpdate()
        }
    }
    public var magic: Float = DisplacementMapFilter.DefaultValues.magic {
        didSet {
            dmFilter.magic = magic
            triggerUpdate()
        }
    }
    public var rim: Float = DisplacementMapFilter.DefaultValues.rim {
        didSet {
            dmFilter.rim = rim
            triggerUpdate()
        }
    }
    public var aberration: Float = DisplacementMapFilter.DefaultValues.abberation {
        didSet {
            dmFilter.abberation = aberration
            triggerUpdate()
        }
    }
    public var blur: Float = 0.0 {
        didSet {
            triggerUpdate()
        }
    }
    public var brightness: Float = 0.0 {
        didSet {
            triggerUpdate()
        }
    }
    public var saturation: Float = 1.0 {
        didSet {
            triggerUpdate()
        }
    }
    public var contrast: Float = 1.0 {
        didSet {
            triggerUpdate()
        }
    }
    public var noise: Float = DisplacementMapFilter.DefaultValues.noise {
        didSet {
            dmFilter.noise = noise
            triggerUpdate()
        }
    }

    override var frame: CGRect {
        didSet {
            if frame != oldValue {
                dmFilter.width = scaleFactor * Float(self.bounds.width)
                dmFilter.height = scaleFactor * Float(self.bounds.height)
                triggerUpdate()
            }
        }
    }
    
    override var bounds: CGRect {
        didSet {
            if bounds != oldValue {
                dmFilter.width = scaleFactor * Float(self.bounds.width)
                dmFilter.height = scaleFactor * Float(self.bounds.height)
                triggerUpdate()
            }
        }
    }
    
    override var center: CGPoint {
        didSet {
            if center != oldValue {
                triggerUpdate()
            }
        }
    }
    
    private class func convertColorSpace(image: CIImage) -> CIImage {
        let filter = CIFilter(name: "CILinearToSRGBToneCurve")
        filter?.setValue(image, forKey: kCIInputImageKey)
        return filter?.outputImage ?? image
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white.withAlphaComponent(0.5)
        
        layer.masksToBounds = true
        let cornerRadius: Float = radius * halfShortSide
        layer.cornerRadius = CGFloat(cornerRadius)
        
        dmFilter.width = scaleFactor * Float(bounds.width)
        dmFilter.height = scaleFactor * Float(bounds.height)
        dmFilter.radius = scaleFactor * cornerRadius
        
        filteredImageView = UIImageView(frame: self.bounds)
        filteredImageView?.translatesAutoresizingMaskIntoConstraints = true
        filteredImageView?.backgroundColor = .clear
        filteredImageView?.contentMode = .scaleAspectFit
        filteredImageView?.clipsToBounds = true
        addSubview(filteredImageView!)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    public func setRandomSettings() {
        blur = Float.random(in: 0.0...10.0)
        setNeedsLayout()
    }
    
    public func showMapToggle() {
        dmFilter.showMap = !dmFilter.showMap
        setNeedsLayout()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if (dmFilter.showMap) {
            filteredImageView?.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        } else {
            let off = -1.0 * CGFloat(padding * halfShortSide)
            filteredImageView?.frame = CGRect(x: off, y: off, width: frame.width-2.0*off, height: frame.height-2.0*off)
        }
        triggerUpdate()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil {
            triggerUpdate()
        }
    }
    
    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        triggerUpdate()
    }
    
    override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        triggerUpdate()
    }
    
    public func triggerUpdate() {
        let cornerRadius: Float = radius * halfShortSide
        layer.cornerRadius = CGFloat(cornerRadius)
        guard let capturedImage = captureUnderlyingImage() else { return }
        var image = capturedImage
        if blur != 0.0 {
            image = applyBlurFilter(image: image, radius: blur*scaleFactor)
        }
        image = applyDisplacementFilter(image: image)
        if brightness != 0.0 || saturation != 1.0 || contrast != 1.0 {
            image = applyColorFilter(image: image, saturation: saturation, brightness: brightness, contrast: contrast)
        }
        
        filteredImage = image
    }
    
    func applyBlurFilter(image: CIImage, radius: Float = 10.0) -> CIImage {
        let filter = CIFilter(name: "CIBoxBlur")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)
        return filter?.outputImage ?? image
    }
    
    func applyColorFilter(image: CIImage, saturation: Float, brightness: Float, contrast: Float) -> CIImage {
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(saturation, forKey: kCIInputSaturationKey)
        filter?.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter?.setValue(contrast, forKey: kCIInputContrastKey)
        return filter?.outputImage ?? image
    }
    
    func applyDisplacementFilter(image: CIImage) -> CIImage {
        let filter = dmFilter
        filter.bgSourceImage = image
        return filter.outputImage ?? image
    }
    
    func applyCropFilter(image: CIImage, rect: CGRect) -> CIImage {
        return image.cropped(to: rect)
    }
    
    @discardableResult
    func captureUnderlyingImage() -> CIImage? {
        guard let sourceView = self.sourceView else { return nil }
        
        // Get frame of current view in sourceView coordinates
        let off:CGFloat = CGFloat(padding * halfShortSide)
        
        let frameInSourceView = self.convert(self.bounds, to: sourceView)
        let size = CGSize(width: self.bounds.size.width + 2.0 * off,
                          height: self.bounds.size.height + 2.0 * off)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            // Offset context to capture the required area
            context.cgContext.translateBy(x: -frameInSourceView.origin.x + off,
                                          y: -frameInSourceView.origin.y + off)
            sourceView.layer.render(in: context.cgContext)
        }
        
        guard let cgImage = image.cgImage else { return nil }
        return CIImage(cgImage: cgImage)
    }

}
