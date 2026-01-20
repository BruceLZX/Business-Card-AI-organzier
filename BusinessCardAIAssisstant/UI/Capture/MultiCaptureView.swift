import SwiftUI
import UIKit

struct MultiCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    let maxPhotos: Int
    let onComplete: ([UIImage]) -> Void

    @State private var capturedImages: [UIImage] = []
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if capturedImages.isEmpty {
                    Text("—")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
                            ForEach(Array(capturedImages.enumerated()), id: \.offset) { index, image in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 110, height: 110)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))

                                    Button(role: .destructive) {
                                        capturedImages.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.white)
                                            .background(Circle().fill(Color.black.opacity(0.6)))
                                    }
                                    .offset(x: 8, y: -8)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                }

                Button {
                    showCamera = true
                } label: {
                    Label(settings.text(.addPhoto), systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal, 16)
                .disabled(capturedImages.count >= maxPhotos)

                Spacer()
            }
            .navigationTitle(settings.text(.captureTitle))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(settings.text(.cancel)) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(settings.text(.done)) {
                        onComplete(capturedImages)
                        dismiss()
                    }
                    .disabled(capturedImages.isEmpty)
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera) { image in
                    if capturedImages.count < maxPhotos {
                        capturedImages.append(image)
                    }
                    showCamera = false
                } onCancel: {
                    showCamera = false
                }
            }
        }
    }
}
