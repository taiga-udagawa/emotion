import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
// MARK: - IBOutlets
    
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    
// MARK: - IBActions
    
    @IBAction func openCameraButtonTapped(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true, completion: nil)
        }
        else {
            showAlert(title: "Camera not available", message: "Camera not available on this device")
        }
    }
    
    @IBAction func openPhotosButtonTapped(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }
        else {
            showAlert(title: "Photo Library not available", message: "Photo library not available on this device")
        }
    }
    
// MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        if let image = info[.originalImage] as? UIImage {
            selectedImageView.image = image
            processImage(image)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
// MARK: - Image Processing
    
    func processImage(_ image: UIImage) {
        let nCluster = 3
        let colors = kmeansProcess(image: image, nCluster: nCluster)
        print("Extracted Colors: \(colors)")
        
        if colors.isEmpty {
            resultLabel.text = "No colors extracted"
            return
        }
        
        // Create color stripe image and set it to resultImageView
        if let colorImage = createColorImage(colors: colors, imageSize: resultImageView.frame.size) {
            resultImageView.image = colorImage
        } else {
            print("Failed to create color image")
        }
        
        let primaryEmotions = analyzePrimaryEmotions(colors: colors)
        print("Primary Emotions: \(primaryEmotions)")
        
        if primaryEmotions.isEmpty {
            resultLabel.text = "No primary emotions detected"
            return
        }
        
        let secondaryEmotions = analyzeSecondaryEmotions(primaryEmotions: primaryEmotions)
        print("Secondary Emotions: \(secondaryEmotions)")
        
        resultLabel.text = """
        Primary Emotions:
        \(primaryEmotions.map { "\($0.emotion) (\($0.intensity))" }.joined(separator: ", "))
        
        Secondary Emotions:
        \(secondaryEmotions.joined(separator: ", "))
        """
    }
    
// MARK: - Primary Emotion Analysis
    
    func analyzePrimaryEmotions(colors: [UIColor]) -> [(emotion: String, intensity: Int)] {
        let primaryEmotionColors: [(emotion: String, color: UIColor)] = [
            ("Joy", UIColor(hue: 60/360, saturation: 1, brightness: 1, alpha: 1)),
            ("Trust", UIColor(hue: 120/360, saturation: 1, brightness: 1, alpha: 1)),
            ("Fear", UIColor(hue: 180/360, saturation: 1, brightness: 1, alpha: 1)),
            ("Surprise", UIColor(hue: 210/360, saturation: 1, brightness: 1, alpha: 1)),
            ("Sadness", UIColor(hue: 240/360, saturation: 1, brightness: 1, alpha: 1)),
            ("Disgust", UIColor(hue: 300/360, saturation: 1, brightness: 1, alpha: 1)),
            ("Anger", UIColor(hue: 0/360, saturation: 1, brightness: 1, alpha: 1)),
            ("Anticipation", UIColor(hue: 30/360, saturation: 1, brightness: 1, alpha: 1))
        ]
        
        return colors.map { color in
            var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
            color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            
            let closestEmotion = primaryEmotionColors.min(by: { lhs, rhs in
                let lhsDiff = abs(lhs.color.hue() - hue)
                let rhsDiff = abs(rhs.color.hue() - hue)
                return lhsDiff < rhsDiff
            })!
            
            let intensity: Int
            if brightness <= 0.33 {
                intensity = 3
            }
            else if brightness >= 0.67 {
                intensity = 1
            }
            else {
                intensity = 2
            }
            
            return (emotion: closestEmotion.emotion, intensity: intensity)
        }
    }
    
// MARK: - Secondary Emotion Analysis
    
    func analyzeSecondaryEmotions(primaryEmotions: [(emotion: String, intensity: Int)]) -> [String] {
        var results: [String] = []
        
        for i in 0..<primaryEmotions.count {
            for j in (i + 1)..<primaryEmotions.count {
                let primary1 = primaryEmotions[i]
                let primary2 = primaryEmotions[j]
                
                if let secondaryEmotion = findSecondaryEmotion(primary1: primary1.emotion, primary2: primary2.emotion) {
                    let intensity = round(Double(primary1.intensity + primary2.intensity) / 2.0)
                    results.append("\(secondaryEmotion) (\(Int(intensity)))")
                }
            }
        }
        
        return results
    }
    
    func findSecondaryEmotion(primary1: String, primary2: String) -> String? {
        let secondaryEmotionMap: [Set<String>: String] = [
            ["Joy", "Trust"]: "Love",
            ["Trust", "Fear"]: "Submission",
            ["Fear", "Surprise"]: "Awe",
            ["Surprise", "Sadness"]: "Rejection",
            ["Sadness", "Disgust"]: "Remorse",
            ["Disgust", "Anger"]: "Contempt",
            ["Anger", "Anticipation"]: "Aggressiveness",
            ["Anticipation", "Joy"]: "Optimism",
            ["Anticipation", "Trust"]: "Fate",
            ["Joy", "Fear"]: "Guilt",
            ["Trust", "Surprise"]: "Curiosity",
            ["Fear", "Sadness"]: "Despair",
            ["Surprise", "Disgust"]: "Indignation",
            ["Sadness", "Anger"]: "Grief",
            ["Disgust", "Anticipation"]: "Sarcasm",
            ["Anger", "Joy"]: "Pride",
            ["Anticipation", "Fear"]: "Anxiety",
            ["Joy", "Surprise"]: "Astonishment",
            ["Trust", "Sadness"]: "Sentimentality",
            ["Fear", "Disgust"]: "Shame",
            ["Surprise", "Anger"]: "Hatred",
            ["Sadness", "Anticipation"]: "Pessimism",
            ["Disgust", "Joy"]: "Unhealthiness",
            ["Anger", "Trust"]: "Superiority"
        ]
        return secondaryEmotionMap[Set([primary1, primary2])]
    }
    
// MARK: - Utility Functions
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func kmeansProcess(image: UIImage, nCluster: Int) -> [UIColor] {
        guard let resizedImage = resizeImage(image, to: CGSize(width: 100, height: 100)) else {
            print("Failed to resize image")
            return []
        }
        
        guard let cgImage = resizedImage.cgImage else {
            print("Failed to get CGImage")
            return []
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            print("Failed to create CGContext")
            return []
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let pixelCount = width * height
        var colors: [[CGFloat]] = []
        
        for i in 0..<pixelCount {
            let pixelIndex = i * bytesPerPixel
            let red = CGFloat(pixelData[pixelIndex]) / 255.0
            let green = CGFloat(pixelData[pixelIndex + 1]) / 255.0
            let blue = CGFloat(pixelData[pixelIndex + 2]) / 255.0
            colors.append([red, green, blue])
        }
        
        guard let centroids = kmeans(colors: colors, k: nCluster) else {
            print("Failed to perform k-means clustering")
            return []
        }
        
        return centroids.map { centroid in
            UIColor(red: centroid[0], green: centroid[1], blue: centroid[2], alpha: 1.0)
        }
    }

    func kmeans(colors: [[CGFloat]], k: Int, maxIterations: Int = 10) -> [[CGFloat]]? {
        guard colors.count >= k else {
            print("Not enough data points for k clusters")
            return nil
        }
        
        var centroids = Array(colors.shuffled().prefix(k))
        var assignments = [Int](repeating: 0, count: colors.count)
        
        for _ in 0..<maxIterations {
            for (i, color) in colors.enumerated() {
                assignments[i] = centroids.enumerated().min(by: { lhs, rhs in
                    distance(lhs.element, color) < distance(rhs.element, color)
                })!.offset
            }
            
            var newCentroids = [[CGFloat]](repeating: [0, 0, 0], count: k)
            var counts = [Int](repeating: 0, count: k)
            
            for (i, assignment) in assignments.enumerated() {
                for j in 0..<3 {
                    newCentroids[assignment][j] += colors[i][j]
                }
                counts[assignment] += 1
            }
            
            for i in 0..<k {
                for j in 0..<3 {
                    newCentroids[i][j] /= CGFloat(max(counts[i], 1))
                }
            }
            
            if newCentroids == centroids {
                break
            }
            
            centroids = newCentroids
        }
        
        return centroids
    }

    func distance(_ a: [CGFloat], _ b: [CGFloat]) -> CGFloat {
        let diff = zip(a, b).map { $0 - $1 }
        return sqrt(diff.map { $0 * $0 }.reduce(0, +))
    }

        func createColorImage(colors: [UIColor], imageSize: CGSize) -> UIImage? {
            let stripeWidth = imageSize.width / CGFloat(colors.count)
            UIGraphicsBeginImageContext(imageSize)
            
            for (index, color) in colors.enumerated() {
                let rect = CGRect(
                    x: CGFloat(index) * stripeWidth,
                    y: 0,
                    width: stripeWidth,
                    height: imageSize.height
                )
                color.setFill()
                UIRectFill(rect)
            }
            
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
    }
                                
// MARK: - UIColor Extension
                                
        extension UIColor {
            func hue() -> CGFloat {
                var hue: CGFloat = 0
                var saturation: CGFloat = 0
                var brightness: CGFloat = 0
                var alpha: CGFloat = 0
                getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
                return hue
            }
        }
