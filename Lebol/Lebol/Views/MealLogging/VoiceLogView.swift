import SwiftUI
import Speech
import AVFoundation

struct VoiceLogView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = VoiceLogViewModel()
    @State private var selectedMealType: MealType
    @State private var coordinator = MealAnalysisCoordinator()
    private let logDate: Date
    var onMealSaved: (() -> Void)?

    init(mealType: MealType = .lunch, logDate: Date = Date(), onMealSaved: (() -> Void)? = nil) {
        _selectedMealType = State(initialValue: mealType)
        self.logDate = logDate
        self.onMealSaved = onMealSaved
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Status icon
                ZStack {
                    Circle()
                        .fill(viewModel.isRecording ? Color.lebolPrimary.opacity(0.15) : Color.lebolDivider)
                        .frame(width: 120, height: 120)

                    if viewModel.isRecording {
                        Circle()
                            .fill(Color.lebolPrimary.opacity(0.08))
                            .frame(width: 160, height: 160)
                            .scaleEffect(viewModel.isRecording ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.isRecording)
                    }

                    Image(systemName: viewModel.isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 40))
                        .foregroundColor(viewModel.isRecording ? .lebolPrimary : .lebolTextSecondary)
                }

                // Instructions / transcript
                if coordinator.isAnalyzing {
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(.lebolPrimary)
                        Text("Analyzing your meal...")
                            .font(LebolFont.subheadline())
                            .foregroundColor(.lebolTextSecondary)
                    }
                } else if !viewModel.transcript.isEmpty {
                    Text(viewModel.transcript)
                        .font(LebolFont.body())
                        .foregroundColor(.lebolTextPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                } else if viewModel.isRecording {
                    Text("Listening... describe what you ate")
                        .font(LebolFont.subheadline())
                        .foregroundColor(.lebolTextSecondary)
                } else {
                    Text("Tap the button and say what you ate")
                        .font(LebolFont.subheadline())
                        .foregroundColor(.lebolTextSecondary)
                }

                // Error
                if let error = viewModel.errorMessage ?? coordinator.errorMessage {
                    Text(error)
                        .font(LebolFont.caption())
                        .foregroundColor(.lebolError)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Record button
                if !coordinator.isAnalyzing {
                    Button {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                        } else {
                            viewModel.startRecording()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(viewModel.isRecording ? Color.lebolPrimary : Color.lebolDivider)
                                .frame(width: 72, height: 72)
                            if viewModel.isRecording {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white)
                                    .frame(width: 24, height: 24)
                            } else {
                                Circle()
                                    .fill(Color.lebolPrimary)
                                    .frame(width: 56, height: 56)
                            }
                        }
                    }
                    .padding(.bottom, 8)

                    // Analyze button (after recording)
                    if !viewModel.transcript.isEmpty && !viewModel.isRecording {
                        Button {
                            Task { await coordinator.analyzeText(viewModel.transcript) }
                        } label: {
                            Text("Analyze Meal")
                        }
                        .buttonStyle(LebolPrimaryButtonStyle())
                    }
                }

                Spacer().frame(height: 16)
            }
            .padding(.horizontal, 20)
            .navigationTitle("Voice Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $coordinator.showingReview) {
                MealReviewView(
                    reviewItems: coordinator.reviewItems,
                    mealName: coordinator.reviewMealName,
                    mealType: selectedMealType,
                    logDate: logDate,
                    onSave: { onMealSaved?(); dismiss() }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - ViewModel

@MainActor @Observable
final class VoiceLogViewModel {
    var isRecording = false
    var transcript = ""
    var errorMessage: String?

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer()

    func startRecording() {
        errorMessage = nil
        transcript = ""

        Task {
            guard await requestMicPermission() else {
                errorMessage = "Microphone access required. Enable it in Settings > Lebol > Microphone."
                return
            }

            let status = await requestSpeechAuthorization()
            switch status {
            case .authorized:
                beginRecordingSession()
            case .denied, .restricted:
                errorMessage = "Speech recognition not authorized. Enable it in Settings."
            case .notDetermined:
                errorMessage = "Speech recognition permission not determined."
            @unknown default:
                errorMessage = "Unknown speech recognition status."
            }
        }
    }

    private func requestMicPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func beginRecordingSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Could not set up audio session."
            return
        }

        audioEngine = AVAudioEngine()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let audioEngine, let recognitionRequest, let speechRecognizer else {
            errorMessage = "Speech recognition not available."
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal == true) {
                    self.stopRecording()
                }
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            errorMessage = "Could not start audio engine."
        }
    }

    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        isRecording = false
    }
}
