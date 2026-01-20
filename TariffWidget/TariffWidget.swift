//
//  TariffWidget.swift
//  TariffWidget
//
//  Created by David Mišmaš on 20. 1. 26.
//

import WidgetKit
import SwiftUI

struct TariffWidget: Widget {
    let kind: String = "TariffWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TariffProvider()) { entry in
            TariffWidgetView(entry: entry)
        }
        .configurationDisplayName("Omrežnina blok")
        .description("Prikaže trenutni blok in kdaj se začne naslednji.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
