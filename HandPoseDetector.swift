import AVFoundation
import Vision
import UIKit

class HandPoseDetector: NSObject {
    private let session = AVCaptureSession()
    private var cameraLayer: AVCaptureVideoPreviewLayer?
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    var onNoteDetected: ((String) -> Void)?

    override init() {
        super.init()
        configureSession()
        configureVisionRequest()
    }
    
    private func configureSession() {
        session.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let cameraInput = try? AVCaptureDeviceInput(device: camera)
        else {
            print("无法访问摄像头")
            return
        }
        
        if session.canAddInput(cameraInput) {
            session.addInput(cameraInput)
        }

        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoOutputQueue"))
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
        }
        session.startRunning()
    }
    
    private func configureVisionRequest() {
        // Configure the hand pose detection request
        handPoseRequest.maximumHandCount = 2 // Detect up to two hands
    }
    
    public func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        self.cameraLayer = layer
        return layer
    }

    private func handleHandPoseObservations(_ observations: [VNHumanHandPoseObservation]) {

        for observation in observations {
            guard let thumb = try? observation.recognizedPoints(.thumb),
                  let index = try? observation.recognizedPoints(.indexFinger),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      let middle = try? observation.recognizedPoints(.middleFinger),
                  let ring = try? observation.recognizedPoints(.ringFinger),
                  let little = try? observation.recognizedPoints(.littleFinger)
            else { continue }

            if let note = detectNoteForHand(thumb: thumb, index: index, middle: middle, ring: ring, little: little) {
                onNoteDetected?(note)
            }
        }
    }

    private func detectNoteForHand(
        thumb: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint],
        index: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint],
        middle: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint],
        ring: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint],
        little: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint]
    ) -> String? {
        guard let thumbTip = thumb[.thumbTip],
              let indexTip = index[.indexTip],
              let middleTip = middle[.middleTip],
              let ringTip = ring[.ringTip],
              let littleTip = little[.littleTip]
        else {
            return nil
        }
        
        let threshold: Float = 0.03
        if distance(thumbTip, indexTip) < threshold {
            return "c"
        } else if distance(thumbTip, middleTip) < threshold {
            return "d"
        } else if distance(thumbTip, ringTip) < threshold {
            return "e"
        } else if distance(thumbTip, littleTip) < threshold {
            return "f"
        }
        return nil
    }
    
    private func distance(_ p1: VNRecognizedPoint, _ p2: VNRecognizedPoint) -> Float {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return Float(sqrt(dx*dx + dy*dy))
    }
}

extension HandPoseDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([handPoseRequest])
            if let results = handPoseRequest.results, !results.isEmpty {
                handleHandPoseObservations(results)
            }
        } catch {
            print("手势检测出错：\(error.localizedDescription)")
        }
    }
} 
