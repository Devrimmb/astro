//
//  AstroWidgetBundle.swift
//  AstroWidget
//
//  Created by Devrim Bal on 13.03.2026.
//

import WidgetKit
import SwiftUI

@main
struct AstroWidgetBundle: WidgetBundle {
    var body: some Widget {
        CosmicStatusWidget()
        MoonPhaseWidget()
        AstroCalendarWidget()
    }
}
