import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        ZStack {
            CameraPreviewLayerView(sessionLayer: viewModel.cameraPreviewLayer)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                Text("当前检测到音符：\(viewModel.detectedNote)")
                    .padding()
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            viewModel.startSession()
        }
    }
}

struct CameraPreviewLayerView: UIViewRepresentable {
    let sessionLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        sessionLayer.frame = view.bounds
        view.layer.addSublayer(sessionLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        sessionLayer.frame = uiView.bounds
    }
}

class ContentViewModel: ObservableObject {
    @Published var detectedNote: String = "无"
    private let detector = HandPoseDetector()
    private let audioPlayer = AudioPlayer()
    
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer {
        return detector.getPreviewLayer()
    }
    
    init() {
        detector.onNoteDetected = { [weak self] note in
            DispatchQueue.main.async {
                self?.detectedNote = note
                self?.audioPlayer.playNote(note)
            }
        }
    }
    
    func startSession() {
            // Request camera permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.detectedNote = "准备就绪"
                    }
                } else {
                    DispatchQueue.main.async {
                        self.detectedNote = "需要相机权限"
                    }
                }
            }
        }
}
