import SwiftUI

/// Content-driven breakpoints; these are not device dimensions or hinge geometry.
struct MobileAdaptiveLayout: Equatable {
    var width: CGFloat = 0
    var height: CGFloat = 0
    var largeText = false

    var roomy: Bool {
        self.width >= 700 && self.height >= 600
    }

    var usesTrailingNavigation: Bool {
        self.roomy && self.width > self.height
    }

    var usesListDetail: Bool {
        self.usesTrailingNavigation && !self.largeText
    }

    var usesTwoColumns: Bool {
        self.roomy && !self.largeText
    }

    var providerColumns: Int {
        self.usesTwoColumns && !self.usesListDetail ? 2 : 1
    }
}

extension EnvironmentValues {
    @Entry var mobileAdaptiveLayout: MobileAdaptiveLayout = .init()
}
