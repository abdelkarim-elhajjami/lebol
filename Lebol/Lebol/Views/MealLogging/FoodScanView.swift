import SwiftUI
import PhotosUI

enum ScanMode: String, CaseIterable {
    case scanFood = "Scan Food"
    case foodLabel = "Food Label"
}

struct FoodScanView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedImage: UIImage?
    @State private var showingCamera = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var selectedMealType: MealType
    @State private var scanMode: ScanMode = .scanFood
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
            ZStack {
                // Camera placeholder / image preview
                VStack {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding()
                    } else {
                        // Scanning frame
                        VStack {
                            Spacer()
                            ZStack {
                                // Corner brackets
                                ScanFrameShape()
                                    .stroke(Color.lebolPrimary, lineWidth: 3)
                                    .frame(width: 250, height: 250)

                                VStack(spacing: 8) {
                                    Image(systemName: scanMode == .scanFood ? "camera.viewfinder" : "doc.viewfinder")
                                        .font(.system(size: 40))
                                        .foregroundColor(.lebolPrimary)
                                    Text(scanMode == .scanFood ? "Photo of your food" : "Photo of nutrition label")
                                        .font(LebolFont.subheadline())
                                        .foregroundColor(.lebolTextSecondary)
                                }
                            }
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.lebolBackground)

                // Bottom controls overlay
                VStack {
                    Spacer()

                    VStack(spacing: 16) {
                        // Mode selector
                        HStack(spacing: 8) {
                            ForEach(ScanMode.allCases, id: \.self) { mode in
                                Button {
                                    scanMode = mode
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: mode == .scanFood ? "camera.viewfinder" : "doc.viewfinder")
                                            .font(.system(size: 14))
                                        Text(mode.rawValue)
                                            .font(LebolFont.caption())
                                    }
                                    .foregroundColor(scanMode == mode ? .lebolTextPrimary : .lebolTextSecondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(scanMode == mode ? Color.white : Color.lebolDivider)
                                    )
                                }
                            }
                        }

                        // Camera controls
                        HStack(spacing: 40) {
                            // Shutter
                            Button {
                                showingCamera = true
                            } label: {
                                Circle()
                                    .stroke(Color.lebolPrimary, lineWidth: 4)
                                    .frame(width: 64, height: 64)
                                    .overlay(
                                        Circle()
                                            .fill(Color.lebolPrimary)
                                            .frame(width: 52, height: 52)
                                    )
                            }

                            // Photo library
                            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 20))
                                    .foregroundColor(.lebolTextSecondary)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(Color.lebolDivider))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                    .padding(.top, 16)
                    .background(
                        Color.lebolCardBackground
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
                    )
                }

                // Analysis progress overlay
                if coordinator.isAnalyzing {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(coordinator.analysisProgress)
                                    .font(LebolFont.subheadline())
                                    .foregroundColor(.white)
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 200)
                    }
                }

                // Error overlay
                if let error = coordinator.errorMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.lebolWarning)
                            Text(error)
                                .font(LebolFont.subheadline())
                                .foregroundColor(.white)
                        }
                        .padding(16)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 200)
                    }
                    .onTapGesture { coordinator.errorMessage = nil }
                }
            }
            .navigationTitle(scanMode.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .lebolDismissToolbar()
            .onChange(of: photoPickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        await analyzeImage(image)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { image in
                    selectedImage = image
                    Task { await analyzeImage(image) }
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

    // MARK: - Analysis (delegates to coordinator)

    private func analyzeImage(_ image: UIImage) async {
        switch scanMode {
        case .scanFood:
            await coordinator.analyzePhoto(image)
        case .foodLabel:
            await coordinator.analyzeLabel(image)
        }
    }
}

// MARK: - Scan Frame Shape

struct ScanFrameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerLength: CGFloat = 30

        // Top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + cornerLength))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + cornerLength, y: rect.minY))

        // Top-right
        path.move(to: CGPoint(x: rect.maxX - cornerLength, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerLength))

        // Bottom-right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerLength))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerLength, y: rect.maxY))

        // Bottom-left
        path.move(to: CGPoint(x: rect.minX + cornerLength, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerLength))

        return path
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
