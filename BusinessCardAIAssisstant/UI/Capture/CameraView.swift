import SwiftUI
import UIKit

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    let onImageCaptured: (UIImage) -> Void

    var body: some View {
        ImagePicker(sourceType: .camera, onImagePicked: { image in
            onImageCaptured(image)
            dismiss()
        }, onCancel: {
            dismiss()
        })
        .ignoresSafeArea()
    }
}
