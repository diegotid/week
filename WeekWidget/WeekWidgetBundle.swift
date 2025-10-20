//
//  WeekWidgetBundle.swift
//  WeekWidget
//
//  Created by Diego Rivera on 20/10/25.
//

import WidgetKit
import SwiftUI

@main
struct WeekWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalendarWeekWidget()
        GaugesWeekWidget()
        WeekWidgetControl()
    }
}
