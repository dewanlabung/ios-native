import CoreMotion
import Foundation

@Observable
final class ShakeDetector {
    private let motionManager = CMMotionManager()
    private let threshold: Double = 2.5
    private let cooldown: TimeInterval = 1.0
    private var lastShakeTime: Date = .distantPast

    var onShake: (() -> Void)?

    func start() {
        guard motionManager.isAccelerometerAvailable else { return }

        let operationQueue = OperationQueue()
        operationQueue.qualityOfService = .userInteractive

        motionManager.startAccelerometerUpdates(to: operationQueue) { [weak self] data, _ in
            guard let self = self, let data = data else { return }

            let x = data.acceleration.x
            let y = data.acceleration.y
            let z = data.acceleration.z

            let magnitude = sqrt(x * x + y * y + z * z)

            if magnitude > self.threshold {
                let now = Date()
                if now.timeIntervalSince(self.lastShakeTime) >= self.cooldown {
                    self.lastShakeTime = now
                    DispatchQueue.main.async {
                        self.onShake?()
                    }
                }
            }
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }
}
