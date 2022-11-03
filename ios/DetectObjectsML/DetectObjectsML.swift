import Vision
import AVFoundation
import MLKitVision
import MLKitTextRecognition

@objc(DetectObjectsMLPlugin)
public class DetectObjectsMLPlugin: NSObject, FrameProcessorPluginBase {
      private static func getFrame(_ frameRect: CGRect) -> [String: CGFloat] {

          let offsetX = (frameRect.midX - ceil(frameRect.width)) / 2.0
          let offsetY = (frameRect.midY - ceil(frameRect.height)) / 2.0

          let x = frameRect.maxX + offsetX
          let y = frameRect.minY + offsetY

          return [
            "x": frameRect.midX + (frameRect.midX - x),
            "y": frameRect.midY + (y - frameRect.midY),
            "width": frameRect.width,
            "height": frameRect.height,
            "boundingCenterX": frameRect.midX,
            "boundingCenterY": frameRect.midY
          ]
      }

      @objc
      public static func callback(_ frame: Frame!, withArgs _: [Any]!) -> Any! {

          guard (CMSampleBufferGetImageBuffer(frame.buffer) != nil) else {
            print("Failed to get image buffer from sample buffer.")
            return nil
          }

          let visionImage = VisionImage(buffer: frame.buffer)

          // TODO: Get camera orientation state
          visionImage.orientation = .up

          var objects: [Object]
          do {
              var options = ObjectDetectorOptions()
              options.detectorMode = .singleImage
              options.shouldEnableMultipleObjects = true
              options.shouldEnableClassification = true
              objects = try ObjectDetector.objectDetector(options: options).results(in: visionImage)
          } catch let error {
            print("Failed to recognize text with error: \(error.localizedDescription).")
            return nil
          }


          var elementArray: [[String: Any]] = []

          for object in objects {
              let frame = object.frame
              let trackingID = object.trackingID

              // If classification was enabled:
              let description = object.labels.enumerated().map { (index, label) in
                  "Label \(index): \(label.text), \(label.confidence)"
                  }.joined(separator:"\n")


              elementArray.append([
                  "description": description,
                  "trackingID": object.trackingID,
                  "frame": getFrame(frame),
              ])
          }

          return elementArray
      }
}
