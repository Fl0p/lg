# Liquid Glass

iOS app implementing a realistic magnifying glass effect using Metal shaders and CoreImage.

<video src=img/githubPreviewdemo.mp4" controls width="350"></video>

[Video Demo](img/simu.mp4)

## Features

- **Displacement Map Filter** - custom Metal-based filter for realistic lens distortion
- **Chromatic Aberration** - color fringing effect for enhanced realism
- **Interactive Parameters**:
  - Width/Height - lens dimensions
  - Radius - corner rounding
  - Scale - magnification strength
  - Bezel - edge curvature shape
  - Padding - edge offset
  - Magic - additional deformation
  - Rim - edge effects
  - Aberration - chromatic aberration intensity
  - Blur/Saturation/Brightness/Contrast - color adjustments
  - Noise - displacement map noise

## Technologies

- Swift
- UIKit
- CoreImage
- Metal Shading Language
- Custom CIKernel filters

## Usage

Run the app:
- Drag the lens around the screen
- Tap background to cycle through images
- Tap lens to toggle displacement map view
- Use sliders to adjust parameters in real-time

## License

MIT License - see [LICENSE](LICENSE) file for details
