// import Foundation
// import UIKit

// @Observable
// @available(*, deprecated, message: "Don't use this class - use AntarcticaTiledMapContentView instead")
// final class AntarcticaMapViewModel {
//     var image: UIImage?
//     var isLoading = false
//     var errorMessage: String?
//     var saveMessage: String?

//     let params: EarthDataMapRequest

//     private let logger: TiledMapLogger

//     init(
//         logger: TiledMapLogger = NoOpLogger(),
//         params: EarthDataMapRequest
//     ) {
//         self.logger = logger
//         self.params = params
//     }

//     @MainActor
//     func load() {
//         isLoading = true
//         errorMessage = nil
//         saveMessage = nil

//         logger.debug("Loading map...", metadata: ["debug": params.debug()])

//         // Note: This ViewModel is deprecated. Use AntarcticaTiledMapContentView instead
//         // which provides proper tiled map functionality
//         isLoading = false
//         errorMessage = "This ViewModel is deprecated. Use AntarcticaTiledMapContentView instead."
//     }

//     func save() {
//         guard let data = image?.pngData() else {
//             logger.warning("No image data to save", metadata: nil)
//             return
//         }

//         let filename = FileManager.default
//             .urls(for: .documentDirectory, in: .userDomainMask)[0]
//             .appendingPathComponent("antarctic.png")

//         do {
//             try data.write(to: filename)
//             logger.info("Map saved to: \(filename.path)", metadata: nil)
//             saveMessage = String(localized: "Map saved in Documents as antarctic.png", bundle: .module)
//         } catch {
//             logger.error("Save error: \(error.localizedDescription)", metadata: nil)
//             errorMessage = String(localized: "Save error: \(error.localizedDescription)", bundle: .module)
//         }
//     }
// }
