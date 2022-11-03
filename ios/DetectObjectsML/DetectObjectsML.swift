import Vision
import AVFoundation
import MLKitVision
import MLKitObjectDetectionCustom
import MLKitCommon

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

          let localModelFilePath = Bundle.main.path(
            forResource: "lite-model_yolo-v5-tflite_tflite_model_1",
            ofType: "tflite"
          )

          let localModel = LocalModel(path: localModelFilePath!)

          let visionImage = VisionImage(buffer: frame.buffer)

          // TODO: Get camera orientation state
          visionImage.orientation = .up

          var objects: [Object]
          var elementArray: [[String: Any]] = []

          do {
              let options = CustomObjectDetectorOptions(localModel: localModel)
              options.detectorMode = .singleImage
              options.shouldEnableClassification = true
              options.shouldEnableMultipleObjects = true
              options.classificationConfidenceThreshold = NSNumber(value: 0.5)
              options.maxPerObjectLabelCount = 3

              objects = try ObjectDetector.objectDetector(options: options).results(in: visionImage)

              print(objects, "objectsobjects")

              for object in objects {
                  let frame = object.frame
                  let trackingID = object.trackingID

                  print("trackingID", trackingID)
                  print("getFrame(frame)", getFrame(frame))

                  // If classification was enabled:
                  let description = object.labels.enumerated().map { (index, label) in
                      "Label \(index): \(label.text), \(label.confidence)"
                      }.joined(separator:"\n")


                  elementArray.append([
                      "description": description,
                      "trackingID": trackingID,
                      "frame": getFrame(frame),
                      "labels": object.labels,
                  ])
              }

          } catch let error {
            print("Failed to recognize text with error: \(error.localizedDescription).")
            return nil
          }

          if (!objects.isEmpty) {
            print("Object detector returned no results.")
          }


           return elementArray

//          return objects
      }
}
