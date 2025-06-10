import CoreImage


class DisplacementMapFilter: CIFilter {
    var bgSourceImage: CIImage?
    var displacementMap: CIImage?
    var showMap: Bool = false
    var width: Float = 200.0
    var height: Float = 160.0
    var radius: Float = 40.0
    var padding: Float = 0.0
    var scale: Float = 50.0
    
    enum DefaultValues {
        static let bezel: Float = 1.0
        static let magic: Float = 0.0
        static let rim: Float = 0.0
        static let noise: Float = 0.0
        static let abberation: Float = 0.0
    }
    
    
    var bezel: Float = DefaultValues.bezel
    var magic: Float = DefaultValues.magic
    var rim: Float = DefaultValues.rim
    var abberation: Float = DefaultValues.abberation
    var noise: Float = DefaultValues.noise

    static var metalData: Data? = {
        guard let url = Bundle.main.url(forResource: "Displacement", withExtension: "ci.metallib") else {
            print("❌ Metal library file not found")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            print("✅ Metal library data loaded successfully")
            return data
        } catch {
            print("❌ Failed to load metal library data with error: \(error)")
            return nil
        }
    }()
    
    static let displacementKernel: CIKernel? = {
        guard let data = metalData else { return nil }
        do {
            let kernel = try CIKernel(functionName: "displacementMapGeneratorKernel", fromMetalLibraryData: data)
            print("✅ Displacement kernel created successfully")
            return kernel
        } catch {
            print("❌ Displacement kernel creation failed: \(error)")
            return nil
        }
    }()
    
    static let displacementMapDistortsionKernel: CIKernel? = {
        guard let data = metalData else { return nil }
        do {
            let kernel = try CIKernel(functionName: "displacementMapDistortsionKernel", fromMetalLibraryData: data)
            print("✅ Chromatic aberration kernel created successfully")
            return kernel
        } catch {
            print("❌ Chromatic aberration kernel creation failed: \(error)")
            return nil
        }
    }()
    
    private var map: CIImage? {
        guard
            let kernel = Self.displacementKernel
        else {
            return nil
        }
        return kernel.apply(
            extent: CGRect(x: 0, y: 0, width: Int(width), height: Int(height)),
            roiCallback: { _, rect in rect },
            arguments: [width, height, radius, bezel, magic, rim, noise]
        )
    }
    
    override var outputImage: CIImage? {
        guard
            let src = bgSourceImage,
            let kernel = Self.displacementMapDistortsionKernel,
            let map = self.map
        else {
            return bgSourceImage
        }
        
//        return bgSourceImage
        if showMap { return map }

        return kernel.apply(
            extent: CGRect(x: 0, y: 0, width: Int(width+2*padding), height: Int(height+2*padding)),
            roiCallback: { _, rect in rect },
            arguments: [src, map, scale, radius, padding, abberation, width, height]
        )

    }
}
