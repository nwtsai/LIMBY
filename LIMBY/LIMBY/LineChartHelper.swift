//
//  LineChartHelper.swift
//  LIMBY
//
//  Created by Team Memorydust on 3/8/18.
//  Copyright © 2018 Team Memorydust. All rights reserved.
//

import Foundation
import UIKit
import Charts

// -----------------------------------------------------------------------------
// Calendaring
// -----------------------------------------------------------------------------

enum TimeRange: Int {
    case minute = 0
    case day = 1
    case week = 2
    case month = 3
    case year = 4
}

func daysIn(_ timeRange: TimeRange) -> Int {
    switch (timeRange) {
    case .minute:
        return 0;
    case .day:
        return 1;
    case .week:
        return 7;
    case .month:
        return 30;  // Divides into 6x 5-day increments.
    case .year:
        return 360; // Divides into 12x 30-day increments.
    }
}

// Produces a date reflecting the specified number of days before the beginning
// of the day tomorrow, which is also the end of the day today.
func daysAgo(_ days: Int) -> Date {
    let cal = Calendar.current
    return cal.date(byAdding: .day, value: -days + 1, to: cal.startOfDay(for: Date()))!
}

// Get the specified number of dates in [MM/DD] format, ending with tomorrow's
// date.
func getDates(_ days: Int) -> [String] {
    let cal = Calendar.current
    let startDate = daysAgo(days)
    return (0...days).map({ i -> String in
        let date = cal.date(byAdding: .day, value: i, to: startDate)!
        return String(cal.component(.month, from: date)) + "/" +
            String(cal.component(.day, from: date))
    })
}

// -----------------------------------------------------------------------------
// Data handling
// -----------------------------------------------------------------------------

class ParticleDataPoint {
    let date: Date
    let value: Double
    
    init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
    
    // This function converts the date received from the perch to a decimal
    // value representing the date.
    func doubleDate(timeRange: TimeRange) -> Double {
        switch (timeRange) {
        case .minute:   // seconds since the beginning of the minute
            return self.date.timeIntervalSince(Calendar.current.startOfDay(for: Date())).truncatingRemainder(dividingBy: 60.0)
        case .day:      // hours since the beginning of the day
            return self.date.timeIntervalSince(daysAgo(daysIn(timeRange))) / 3600.0
        default:        // days since the appropriate number of days ago
            return self.date.timeIntervalSince(daysAgo(daysIn(timeRange))) / 86400.0
        }
    }
    
    // This function converts the value received from the perch to a weight in
    // grams. Could use some kind of calibration for a better conversion.
    func weight() -> Double {
        return abs(0.0011427 * self.value)
    }
    
    func toChartDataEntry(timeRange: TimeRange) -> ChartDataEntry {
        return ChartDataEntry(x: self.doubleDate(timeRange: timeRange), y: self.weight())
    }
}

// Get values from Particle device.
func getValues() -> [ParticleDataPoint] {
    var data = [ParticleDataPoint]()
    for str in DataQueue.singleton.queue {
        let components = str.components(separatedBy: "\t")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE MMM dd HH:mm:ss yyyy"
        if let date = dateFormatter.date(from: components[1]),
            let value = Double(components[0]) {
            data.append(ParticleDataPoint(date: date, value: value))
        }
    }
    return data
}

// -----------------------------------------------------------------------------
// Chart
// -----------------------------------------------------------------------------

// Get x-axis labels based on the selected timeRange.
func getXLabels(timeRange: TimeRange) -> [String] {
    switch timeRange {
    case .minute:
        return (0...60).map({ ":" + String(format: "%02d", $0) })
    case .day:
        return ["12 AM", "1 AM", "2 AM", "3 AM", "4 AM", "5 AM", "6 AM",
                "7 AM", "8 AM", "9 AM", "10 AM", "11 AM",
                "12 PM", "1 PM", "2 PM", "3 PM", "4 PM", "5 PM", "6 PM",
                "7 PM", "8 PM", "9 PM", "10 PM", "11 PM", "12 AM"]
    default:
        return getDates(daysIn(timeRange))
    }
}

class CustomBalloonMarker: BalloonMarker {
    var decimals: Int = 2
    
    public init() {
        super.init(color: UIColor.darkGray,
                   font: LineChartViewController.CHART_FONT,
                   textColor: UIColor.white,
                   insets: UIEdgeInsets(top: 7.0, left: 7.0, bottom: 7.0, right: 7.0))
        self.minimumSize = CGSize(width: 35.0, height: 35.0)
    }
    
    open override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        setLabel(String(format: "%." + String(decimals) + "f", entry.y))
    }
}
