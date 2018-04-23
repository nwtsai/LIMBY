//
//  LineChartViewController.swift
//  LIMBY
//
//  Created by Team Memorydust on 2/8/18.
//  Copyright © 2018 Team Memorydust. All rights reserved.
//

import Foundation
import UIKit
import Charts

class LineChartViewController: UIViewController, UITextFieldDelegate {
    
    // -------------------------------------------------------------------------
    // Initialization
    // -------------------------------------------------------------------------

    static let CHART_FONT = UIFont.systemFont(ofSize: 11)
    static let CIRCLE_RADIUS = CGFloat(4.0)
    static let FILTER_THRESHOLD = 0.75
    static let LEGEND_SQUARE_SIZE = CGFloat(16)
    static let LINE_WIDTH = CGFloat(2.0)
    static let NATHANS_CONSTANT = CGFloat(17)
    static let REFRESH_INTERVAL = 2.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lineChartView.noDataText = "No data available."
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        timeRange = TimeRange(rawValue: segmentedController.selectedSegmentIndex)!
        let _ = DataQueue.singleton.subscribe(prefix: "weight")
        plotLineChart(plotMode: PlotMode.initial)
        Timer.scheduledTimer(withTimeInterval:
            LineChartViewController.REFRESH_INTERVAL, repeats: true) { _ in
            self.plotLineChart(plotMode: PlotMode.update)
        }
    }
    
    // -------------------------------------------------------------------------
    // IBOutlet variables
    // -------------------------------------------------------------------------
    
    @IBOutlet var lineChartView: LineChartView!
    @IBOutlet weak var segmentedController: UISegmentedControl!
    
    // TimeRange to reflect the state of the segmented controller.
    var timeRange = TimeRange(rawValue: 0)!
    
    // -------------------------------------------------------------------------
    // IBAction handlers
    // -------------------------------------------------------------------------
    
    @IBAction func unsubscribe(_ sender: Any) {
        DataQueue.singleton.unsubscribe()
        DataQueue.singleton.queue.removeAll()
        self.navigationController?.popViewController(animated: true)
    }
    
    // Modify line chart whenever segment index changes.
    @IBAction func segmentChanged(_ sender: Any) {
        timeRange = TimeRange(rawValue: segmentedController.selectedSegmentIndex)!
        plotLineChart(plotMode: PlotMode.initial)
    }
    
    // -------------------------------------------------------------------------
    // Plotting function
    // -------------------------------------------------------------------------
    
    enum PlotMode {
        case initial
        case update
    }
    
    // Plot line chart given a time interval and values
    func plotLineChart(plotMode: PlotMode) {
        
        // Set up x-axis labels.
        let xLabels = getXLabels(timeRange: timeRange)
        lineChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: xLabels)
        
        // Prepare data entries.
        var dataEntries = [ChartDataEntry]()
        for dataPoint in getValues() {
            let cde = dataPoint.toChartDataEntry(timeRange: timeRange)
            if !dataEntries.isEmpty && cde.x < dataEntries.last!.x {
                dataEntries.removeAll()
            }
            dataEntries.append(cde)
        }
        
        // Create data set.
        let dataSet = LineChartDataSet(values: dataEntries, label: "Bird weight (g)")
        dataSet.axisDependency = .left
        dataSet.circleColors = [UIColor.gray]
        dataSet.circleRadius = LineChartViewController.CIRCLE_RADIUS
        dataSet.colors = [UIColor.gray]
        dataSet.drawCircleHoleEnabled = false
        
        // Add data set to view.
        lineChartView.data = LineChartData(dataSet: dataSet)
        lineChartView.data!.setDrawValues(false)
        
        // Draw average line
        lineChartView.leftAxis.removeAllLimitLines()
        let initial_avg = dataEntries.reduce(0, { $0 + $1.y }) / Double(dataEntries.count)
        for entry in dataEntries {
            if entry.y < LineChartViewController.FILTER_THRESHOLD * initial_avg {
                entry.y = 0
            }
        }
        let dataEntries_filtered = dataEntries.filter({ $0.y > 0.0 })
        let filtered_avg = dataEntries_filtered.reduce(0, { $0 + $1.y }) / Double(dataEntries_filtered.count)
        if filtered_avg > 0.0 {
            let ll = ChartLimitLine(limit: filtered_avg, label: "Average: " +
                                    String(format: "%.2f", filtered_avg))
            ll.labelPosition = .rightTop
            ll.lineColor = UIColor.black
            ll.lineWidth = 2
            ll.valueFont = LineChartViewController.CHART_FONT
            lineChartView.leftAxis.addLimitLine(ll)
        }
        
        // x-axis
        lineChartView.xAxis.axisLineColor = UIColor.black
        lineChartView.xAxis.axisLineWidth = LineChartViewController.LINE_WIDTH
        lineChartView.xAxis.axisMinimum = 0.0
        lineChartView.xAxis.labelFont = LineChartViewController.CHART_FONT
        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.xAxis.labelRotationAngle = -45.0
        switch timeRange {
        case .minute:
            lineChartView.xAxis.granularity = 5.0
            lineChartView.xAxis.axisMaximum = 60.0
        case .day:
            lineChartView.xAxis.granularity = 3.0
            lineChartView.xAxis.axisMaximum = 24.0
        case .week:
            lineChartView.xAxis.granularity = 1.0
            lineChartView.xAxis.axisMaximum = Double(daysIn(timeRange))
        case .month:
            lineChartView.xAxis.granularity = 5.0
            lineChartView.xAxis.axisMaximum = Double(daysIn(timeRange))
        case .year:
            lineChartView.xAxis.granularity = 30.0
            lineChartView.xAxis.axisMaximum = Double(daysIn(timeRange))
        }
        lineChartView.xAxis.labelCount = Int(lineChartView.xAxis.axisMaximum /
            lineChartView.xAxis.granularity)
        
        // Left y-axis
        lineChartView.leftAxis.axisLineColor = UIColor.black
        lineChartView.leftAxis.axisLineWidth = LineChartViewController.LINE_WIDTH
        lineChartView.leftAxis.axisMinimum = 0.0
        lineChartView.leftAxis.labelFont = LineChartViewController.CHART_FONT
        lineChartView.leftAxis.granularity = 1.0
 
        // Right y-axis
        lineChartView.rightAxis.enabled = false
        
        // Description & legend
        lineChartView.chartDescription?.text = ""
        lineChartView.legend.font = LineChartViewController.CHART_FONT
        lineChartView.legend.formSize = LineChartViewController.LEGEND_SQUARE_SIZE
        
        // Margins
        lineChartView.extraLeftOffset = LineChartViewController.NATHANS_CONSTANT / 2
        lineChartView.extraRightOffset = LineChartViewController.NATHANS_CONSTANT
        lineChartView.extraTopOffset = LineChartViewController.NATHANS_CONSTANT
        lineChartView.extraBottomOffset = 0
        
        // Interaction
        lineChartView.backgroundColor = UIColor.white
        lineChartView.marker = CustomBalloonMarker()
        lineChartView.pinchZoomEnabled = false
        lineChartView.scaleXEnabled = false
        lineChartView.scaleYEnabled = false
        
        // Animate
        switch plotMode {
        case .initial:
            lineChartView.animate(xAxisDuration: 0.0, yAxisDuration: 1.0)
        case .update:
            lineChartView.animate(xAxisDuration: 0.0, yAxisDuration: 0.0)
        }
        
        // Update graph with new changes
        lineChartView.notifyDataSetChanged()
    }
}
