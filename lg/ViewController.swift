//
//  ViewController.swift
//  lg
//
//  Created by Flop But on 10/06/2025.
//

import UIKit

// Custom UIView with overridden draw method
class CustomDrawView: UIView {
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        print("CustomDrawView draw method called with rect: \(rect)")
    }
}

class ViewController: UIViewController {

    private var backgroundView: UIView!
    private var imageView: UIImageView!
    private var lgView: LGView!
    private var dragManager: DragManager?
    private var slidersView: UIView!
    
    // Sliders
    private var widthSlider: UISlider!
    private var radiusSlider: UISlider!
    private var scaleSlider: UISlider!
    private var heightSlider: UISlider!
    private var bezelSlider: UISlider!
    private var paddingSlider: UISlider!
    private var magicSlider: UISlider!
    private var rimSlider: UISlider!
    private var aberrationSlider: UISlider!
    private var blurSlider: UISlider!
    private var saturationSlider: UISlider!
    private var brightnessSlider: UISlider!
    private var contrastSlider: UISlider!
    private var noiseSlider: UISlider!
    
    // Labels
    private var widthLabel: UILabel!
    private var radiusLabel: UILabel!
    private var scaleLabel: UILabel!
    private var heightLabel: UILabel!
    private var bezelLabel: UILabel!
    private var paddingLabel: UILabel!
    private var magicLabel: UILabel!
    private var rimLabel: UILabel!
    private var aberrationLabel: UILabel!
    private var blurLabel: UILabel!
    private var saturationLabel: UILabel!
    private var brightnessLabel: UILabel!
    private var contrastLabel: UILabel!
    private var noiseLabel: UILabel!
    
    // Array with image names for cyclic switching
    private let backgroundImages = ["bg1", "bg2", "bg3", "bg4", "bg5", "bg6"]
    private var currentImageIndex = 0
    
    override func loadView() {
        // Set custom view as root view controller
        self.view = CustomDrawView(frame: UIScreen.main.bounds)
        self.view.backgroundColor = .red
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundView = UIView(frame: view.bounds)
        backgroundView.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(backgroundView)
        
        imageView = UIImageView(frame: backgroundView.bounds)
        imageView.translatesAutoresizingMaskIntoConstraints = true
        imageView.image = UIImage(named: "bg1")
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true  // Enable user interaction
        backgroundView.addSubview(imageView)
        
        // Add gesture recognizer for background tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        imageView.addGestureRecognizer(tapGesture)
        
        lgView = LGView(frame: CGRect(x: 50, y: 100, width: 200, height: 160))

        lgView.scale = 100
        lgView.translatesAutoresizingMaskIntoConstraints = false
        lgView.sourceView = backgroundView
        view.addSubview(lgView)
        
        // Enable dragging functionality via external DragManager
        dragManager = DragManager(targetView: lgView)
        dragManager?.constrainToSuperview = true
        
        // Add gesture recognizer for lgView tap
        let lgViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(lgViewTapped))
        lgView.addGestureRecognizer(lgViewTapGesture)
        
        setupSliders()
    }
    
    // Background image tap handler
    @objc private func backgroundTapped() {
        // Switch to next image
        currentImageIndex = (currentImageIndex + 1) % backgroundImages.count
        
        // Set new image
        let imageName = backgroundImages[currentImageIndex]
        imageView.image = UIImage(named: imageName)
        
        print("Background changed to: \(imageName)")

        lgView.triggerUpdate()
    }
    
    // LGView tap handler
    @objc private func lgViewTapped() {
        lgView.showMapToggle()
        //lgView.setRandomSettings()
        //print("LGView random settings applied")
    }
    
    // Setup sliders in 2x6 grid at the bottom of the screen
    private func setupSliders() {
        let sliderHeight: CGFloat = 20
        let labelHeight: CGFloat = 20
        let spacingX: CGFloat = 20
        let spacingY: CGFloat = 20
        let sideMargin: CGFloat = 20
        let bottomMargin: CGFloat = 50
        
        let totalWidth = view.bounds.width - (sideMargin * 2)
        let sliderWidth = (totalWidth - spacingX) / 2
        let startY = view.bounds.height - bottomMargin - (sliderHeight * 7) - (spacingY * 6) - (labelHeight * 7)
        
        slidersView = UIView(frame: CGRect(x: 0, y: startY, width: view.bounds.width, height: view.bounds.height - startY))
        slidersView.translatesAutoresizingMaskIntoConstraints = true
        backgroundView.addSubview(slidersView)
        
        // Left column
        let leftX = sideMargin
        
        // Row 1 Left - Width
        widthLabel = createLabel(text: "Width: 200", x: leftX, y: 0, width: sliderWidth)
        slidersView.addSubview(widthLabel)
        
        widthSlider = UISlider(frame: CGRect(x: leftX, y: labelHeight, width: sliderWidth, height: sliderHeight))
        widthSlider.minimumValue = 50
        widthSlider.maximumValue = 300
        widthSlider.value = Float(lgView.frame.width)
        widthSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slidersView.addSubview(widthSlider)
        widthLabel.text = String(format: "Width: %.0f", widthSlider.value)
        
        // Row 2 Left - Radius
        let slider2Y = labelHeight + sliderHeight + spacingY
        radiusLabel = createLabel(text: "Radius: 0.50", x: leftX, y: slider2Y, width: sliderWidth)
        slidersView.addSubview(radiusLabel)
        
        radiusSlider = UISlider(frame: CGRect(x: leftX, y: slider2Y + labelHeight, width: sliderWidth, height: sliderHeight))
        radiusSlider.minimumValue = 0.0
        radiusSlider.maximumValue = 1.0
        radiusSlider.value = lgView.radius
        radiusSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slidersView.addSubview(radiusSlider)
        radiusLabel.text = String(format: "Radius: %.2f", radiusSlider.value)
        
        // Row 3 Left - Magic
        let slider3Y = (labelHeight + sliderHeight + spacingY) * 2
        magicLabel = createLabel(text: "Magic: 0.00", x: leftX, y: slider3Y, width: sliderWidth)
        slidersView.addSubview(magicLabel)
        
        magicSlider = UISlider(frame: CGRect(x: leftX, y: slider3Y + labelHeight, width: sliderWidth, height: sliderHeight))
        magicSlider.minimumValue = -5.0
        magicSlider.maximumValue = 5.0
        magicSlider.value = lgView.magic
        magicSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slidersView.addSubview(magicSlider)
        magicLabel.text = String(format: "Magic: %.2f", magicSlider.value)
        
        // Row 4 Left - Noise
        let slider4Y = (labelHeight + sliderHeight + spacingY) * 3
        noiseLabel = createLabel(text: "Noise: 0.00", x: leftX, y: slider4Y, width: sliderWidth)
        slidersView.addSubview(noiseLabel)
        
        noiseSlider = UISlider(frame: CGRect(x: leftX, y: slider4Y + labelHeight, width: sliderWidth, height: sliderHeight))
        noiseSlider.minimumValue = 0.0
        noiseSlider.maximumValue = 1.0
        noiseSlider.value = lgView.noise
        noiseSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slidersView.addSubview(noiseSlider)
        noiseLabel.text = String(format: "Noise: %.2f", noiseSlider.value)
        
        // Row 5 Left - Scale
        let slider5Y = (labelHeight + sliderHeight + spacingY) * 4
        scaleLabel = createLabel(text: "Scale: 100", x: leftX, y: slider5Y, width: sliderWidth)
        slidersView.addSubview(scaleLabel)
        
        scaleSlider = UISlider(frame: CGRect(x: leftX, y: slider5Y + labelHeight, width: sliderWidth, height: sliderHeight))
        scaleSlider.minimumValue = -300.0
        scaleSlider.maximumValue = 300.0
        scaleSlider.value = lgView.scale
        scaleSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slidersView.addSubview(scaleSlider)
        scaleLabel.text = String(format: "Scale: %.0f", scaleSlider.value)
        
        // Row 6 Left - Aberration
        let slider6Y = (labelHeight + sliderHeight + spacingY) * 5
        aberrationLabel = createLabel(text: "Aberration: 0.00", x: leftX, y: slider6Y, width: sliderWidth)
        slidersView.addSubview(aberrationLabel)
        
        aberrationSlider = UISlider(frame: CGRect(x: leftX, y: slider6Y + labelHeight, width: sliderWidth, height: sliderHeight))
        aberrationSlider.minimumValue = -1.0
        aberrationSlider.maximumValue = 1.0
        aberrationSlider.value = lgView.aberration
        aberrationSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slidersView.addSubview(aberrationSlider)
        aberrationLabel.text = String(format: "Aberration: %.2f", aberrationSlider.value)
        
        // Row 7 Left - Brightness
        let slider7Y = (labelHeight + sliderHeight + spacingY) * 6
        brightnessLabel = createLabel(text: "Brightness: 0.00", x: leftX, y: slider7Y, width: sliderWidth)
        slidersView.addSubview(brightnessLabel)
        
        brightnessSlider = UISlider(frame: CGRect(x: leftX, y: slider7Y + labelHeight, width: sliderWidth, height: sliderHeight))
        brightnessSlider.minimumValue = -0.5
        brightnessSlider.maximumValue = 0.5
        brightnessSlider.value = lgView.brightness
        brightnessSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slidersView.addSubview(brightnessSlider)
        brightnessLabel.text = String(format: "Brightness: %.2f", brightnessSlider.value)
        
        // Right column
        let rightX = leftX + sliderWidth + spacingX
        
        // Row 1 Right - Height
        heightLabel = createLabel(text: "Height: 160", x: rightX, y: 0, width: sliderWidth)
        slidersView.addSubview(heightLabel)
        
        heightSlider = UISlider(frame: CGRect(x: rightX, y: labelHeight, width: sliderWidth, height: sliderHeight))
        heightSlider.minimumValue = 50
        heightSlider.maximumValue = 300
        heightSlider.value = Float(lgView.frame.height)
        heightSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slidersView.addSubview(heightSlider)
        heightLabel.text = String(format: "Height: %.0f", heightSlider.value)
        
        // Row 2 Right - Bezel
        bezelLabel = createLabel(text: "Bezel: 1.00", x: rightX, y: slider2Y, width: sliderWidth)
        slidersView.addSubview(bezelLabel)
        
        bezelSlider = UISlider(frame: CGRect(x: rightX, y: slider2Y + labelHeight, width: sliderWidth, height: sliderHeight))
        bezelSlider.minimumValue = 0.0
        bezelSlider.maximumValue = 5.0
        bezelSlider.value = lgView.bezel
        bezelSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slidersView.addSubview(bezelSlider)
        bezelLabel.text = String(format: "Bezel: %.2f", bezelSlider.value)
        
        // Row 3 Right - Rim
        rimLabel = createLabel(text: "Rim: 0.00", x: rightX, y: slider3Y, width: sliderWidth)
        slidersView.addSubview(rimLabel)
        
        rimSlider = UISlider(frame: CGRect(x: rightX, y: slider3Y + labelHeight, width: sliderWidth, height: sliderHeight))
        rimSlider.minimumValue = -3.0
        rimSlider.maximumValue = 3.0
        rimSlider.value = lgView.rim
        rimSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slidersView.addSubview(rimSlider)
        rimLabel.text = String(format: "Rim: %.2f", rimSlider.value)
        
        // Row 4 Right - Blur
        blurLabel = createLabel(text: "Blur: 0.0", x: rightX, y: slider4Y, width: sliderWidth)
        slidersView.addSubview(blurLabel)
        
        blurSlider = UISlider(frame: CGRect(x: rightX, y: slider4Y + labelHeight, width: sliderWidth, height: sliderHeight))
        blurSlider.minimumValue = 0.0
        blurSlider.maximumValue = 50.0
        blurSlider.value = lgView.blur
        blurSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slidersView.addSubview(blurSlider)
        blurLabel.text = String(format: "Blur: %.1f", blurSlider.value)
        
        // Row 5 Right - Padding
        paddingLabel = createLabel(text: "Padding: 0.00", x: rightX, y: slider5Y, width: sliderWidth)
        slidersView.addSubview(paddingLabel)
        
        paddingSlider = UISlider(frame: CGRect(x: rightX, y: slider5Y + labelHeight, width: sliderWidth, height: sliderHeight))
        paddingSlider.minimumValue = 0.0
        paddingSlider.maximumValue = 1.0
        paddingSlider.value = lgView.padding
        paddingSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slidersView.addSubview(paddingSlider)
        paddingLabel.text = String(format: "Padding: %.2f", paddingSlider.value)
        
        // Row 6 Right - Saturation
        saturationLabel = createLabel(text: "Saturation: 1.00", x: rightX, y: slider6Y, width: sliderWidth)
        slidersView.addSubview(saturationLabel)
        
        saturationSlider = UISlider(frame: CGRect(x: rightX, y: slider6Y + labelHeight, width: sliderWidth, height: sliderHeight))
        saturationSlider.minimumValue = 0.0
        saturationSlider.maximumValue = 2.0
        saturationSlider.value = lgView.saturation
        saturationSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slidersView.addSubview(saturationSlider)
        saturationLabel.text = String(format: "Saturation: %.2f", saturationSlider.value)
        
        // Row 7 Right - Contrast
        contrastLabel = createLabel(text: "Contrast: 1.00", x: rightX, y: slider7Y, width: sliderWidth)
        slidersView.addSubview(contrastLabel)
        
        contrastSlider = UISlider(frame: CGRect(x: rightX, y: slider7Y + labelHeight, width: sliderWidth, height: sliderHeight))
        contrastSlider.minimumValue = 0.0
        contrastSlider.maximumValue = 2.0
        contrastSlider.value = lgView.contrast
        contrastSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slidersView.addSubview(contrastSlider)
        contrastLabel.text = String(format: "Contrast: %.2f", contrastSlider.value)
    }
    
    // Single handler for all sliders using switch case
    @objc private func sliderValueChanged(_ sender: UISlider) {
        switch sender {
        case widthSlider:
            lgView.frame.size.width = CGFloat(sender.value)
            widthLabel.text = String(format: "Width: %.0f", sender.value)
        case heightSlider:
            lgView.frame.size.height = CGFloat(sender.value)
            heightLabel.text = String(format: "Height: %.0f", sender.value)
        case radiusSlider:
            lgView.radius = Float(sender.value)
            radiusLabel.text = String(format: "Radius: %.2f", sender.value)
        case bezelSlider:
            lgView.bezel = Float(sender.value)
            bezelLabel.text = String(format: "Bezel: %.2f", sender.value)
        case scaleSlider:
            lgView.scale = Float(sender.value)
            scaleLabel.text = String(format: "Scale: %.0f", sender.value)
        case paddingSlider:
            lgView.padding = Float(sender.value)
            paddingLabel.text = String(format: "Padding: %.2f", sender.value)
        case magicSlider:
            lgView.magic = Float(sender.value)
            magicLabel.text = String(format: "Magic: %.2f", sender.value)
        case rimSlider:
            lgView.rim = Float(sender.value)
            rimLabel.text = String(format: "Rim: %.2f", sender.value)
        case aberrationSlider:
            lgView.aberration = Float(sender.value)
            aberrationLabel.text = String(format: "Aberration: %.2f", sender.value)
        case blurSlider:
            lgView.blur = Float(sender.value)
            blurLabel.text = String(format: "Blur: %.1f", sender.value)
        case saturationSlider:
            lgView.saturation = Float(sender.value)
            saturationLabel.text = String(format: "Saturation: %.2f", sender.value)
        case brightnessSlider:
            lgView.brightness = Float(sender.value)
            brightnessLabel.text = String(format: "Brightness: %.2f", sender.value)
        case contrastSlider:
            lgView.contrast = Float(sender.value)
            contrastLabel.text = String(format: "Contrast: %.2f", sender.value)
        case noiseSlider:
            lgView.noise = Float(sender.value)
            noiseLabel.text = String(format: "Noise: %.2f", sender.value)
        default:
            print("Unknown slider value changed to: \(sender.value)")
        }
    }

    private func createLabel(text: String, x: CGFloat, y: CGFloat, width: CGFloat) -> UILabel {
        let label = UILabel(frame: CGRect(x: x, y: y, width: width, height: 20))
        label.text = text
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }
}

