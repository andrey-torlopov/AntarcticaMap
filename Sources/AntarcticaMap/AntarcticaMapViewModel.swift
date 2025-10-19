import Foundation
import UIKit

@Observable
@available(*, deprecated, message: "Don't use this class")
final class AntarcticaMapViewModel {
    var image: UIImage?
    var isLoading = false
    var errorMessage: String?
    var saveMessage: String?

    let params: EarthDataMapRequest

    private let service: any EarthDataMapServicing
    private let logger: Letopis

    init(
        service: any EarthDataMapServicing,
        logger: Letopis,
        params: EarthDataMapRequest = EarthDataMapRequest(
            minX: -4_000_000,
            minY: -4_000_000,
            maxX: 4_000_000,
            maxY: 4_000_000,
            width: 512,
            height: 512,
            time: "2023-01-01",
            layers: "MODIS_Terra_CorrectedReflectance_TrueColor"
        )
    ) {
        self.service = service
        self.logger = logger
        self.params = params
    }

    @MainActor
    func load() {
        isLoading = true
        errorMessage = nil
        saveMessage = nil

        logger
            .event(DevelopmentEventType.debug)
            .action(DevelopmentAction.breakpoint)
            .source()
            .payload(["debug": params.debug()])
            .debug("Loading map...")

        Task { [weak self] in
            guard let self else { return }
            let result = await service.fetchMap(params: params)
            await MainActor.run {
                isLoading = false
                switch result {
                case .success(let data):
                    logger.info("Map loaded successfully, size: \(data.count) bytes")
                    image = UIImage(data: data)
                case .failure(let error):
                    logger.error(error)
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func save() {
        guard let data = image?.pngData() else {
            logger.warning("No image data to save")
            return
        }

        let filename = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("antarctic.png")

        do {
            try data.write(to: filename)
            logger.info("Map saved to: \(filename.path)")
            saveMessage = String(localized: "Map saved in Documents as antarctic.png", bundle: .module)
        } catch {
            logger.error(error)
            errorMessage = String(localized: "Save error: \(error.localizedDescription)", bundle: .module)
        }
    }
}
