//
//  ViewController.swift
//  ChartTest1
//
//  Created by Andreas Neusüß on 09.05.19.
//  Copyright © 2019 Anerma. All rights reserved.
//

import UIKit
import Audiograph

/// ViewController that instantiats the data store and configures the chart view. Interactions with the chart are done in the ChartView itself.
/// Changes in the selected range are handled in `segmentedControlValueChanged` where the data source is asked to give new data. It is converted into points for the ChartsView to display.
/// Interactions with the chart are handled in the methods of `ChartViewDelegate` which this viewcontroller implements.
class ViewController: UIViewController {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var chartView: ChartView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var demoDataExplanationLabel: UILabel!
    
    @IBOutlet weak var audiographSegmentedControl: UISegmentedControl!
    private lazy var model: DataStore = {
        let path = Bundle.main.path(forResource: "GDAXI", ofType: "csv")
        let input = try! String(contentsOfFile: path!)
        
        return DataStore(contentsOfCSV: input)
    }()

    private let feedbackGenerator = UISelectionFeedbackGenerator()
    private let colorMinus = UIColor(named: "ColorMinus")!
    private let colorPlus = UIColor(named: "ColorPlus")!
    let audiograph: Audiograph = {
        // Being lazy is ok for showcase. The ChartView uses a more sophisticated language.
        let localizations = AudiographLocalizations.defaultEnglish
        
        return Audiograph(localizations: localizations)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        chartView.delegate = self
        segmentedControlValueChanged(segmentedControl)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        feedbackGenerator.prepare()
    }

    /// Get the new data from the data store according to the selected segment. That data is transformed into points and passed to the ChartView.
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        
        let newData: [StockData]
        switch sender.selectedSegmentIndex {
        case 0: // 5T
            newData = model.firstFiveDays
            demoDataExplanationLabel.isHidden = false
        case 1: // 1M
            newData = model.month
            demoDataExplanationLabel.isHidden = true
        case 2: // 6M
            newData = model.sixMonths
            demoDataExplanationLabel.isHidden = true
        case 3: // 1Y
            newData = model.year
            demoDataExplanationLabel.isHidden = true
        case 4: // 5Y
            newData = model.fiveYears
            demoDataExplanationLabel.isHidden = true
        default:
            fatalError()
        }
        
        // Store the current data set for later.
        model.currentDataSet = newData
        
        // Define the color of the chart:
        if let rightElement = model.currentDataSet.last, let leftElement = model.currentDataSet.first {
            let chartColor: UIColor = rightElement.close < leftElement.close ? colorMinus : colorPlus
            chartView.chartColor = chartColor
        }
        
        // Convert data points to CGPoints so that they can be displayed by the ChartView. They are scaled by the view afterwards. The chart view needs them starting at the rightmost element.
        let pointsFromRightToLeft = displayablePoints()
        
        chartView.transform(to: pointsFromRightToLeft)
        highlightDidChanged(to: newData.count - 1)
    }
    
    @IBAction func audiographSegmentedControlChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            audiograph.playingDuration = .short
        case 1:
            audiograph.playingDuration = .recommended
        case 2:
            audiograph.playingDuration = .long
        case 3:
            audiograph.playingDuration = .exactly(.seconds(10))
        default:
            fatalError("This case was implemented in UI but not in code.")
        }
    }
    
    @IBAction func playSoundButtonPressed(_ sender: Any) {
        /*
         The first way: manually triggering the Audiograph by calling `.play`.
         */
        audiograph.play(graphContent: chartView.graphContent)
    }
    
    /// Converts `currentData` from the model into an array of `[CGPoint]`. They can be used to pass into chart view or to derive audiograph data.
    /// The first element is the leftmost point.
    private func displayablePoints() -> [CGPoint] {
        model.currentDataSet.map { data -> CGPoint in
            let xComponent = data.date.timeIntervalSince1970
            let yComponent = data.close
            
            return CGPoint(x: xComponent, y: yComponent)
        }
    }
    
}

extension ViewController: ChartViewDelegate {
    func highlightDidChanged(to elementAtIndex: Int) {
        guard elementAtIndex < model.currentDataSet.count else { return }
        let selectedElement = model.currentDataSet[elementAtIndex]
        let leftElement = model.currentDataSet.first!
        
        // Color is chosen relative to the oldest element which sets the baseline.
        let colorOfPriceLabel: UIColor = leftElement.close > selectedElement.close ? colorMinus : colorPlus
        
        updatePriceLabel(to: String.init(format: "%.2f", selectedElement.close), in: colorOfPriceLabel)
        
        // Only give feedback when not too many points are displayed. That is the case in the 1Y and 5Y state.
        if segmentedControl.selectedSegmentIndex != 4 && segmentedControl.selectedSegmentIndex != 5 {
            feedbackGenerator.selectionChanged()
        }
    }
    
    func hightlightDidEnd() {
        if let rightElement = model.currentDataSet.last, let leftElement = model.currentDataSet.first {
            let colorOfPriceLabel: UIColor = rightElement.close < leftElement.close ? colorMinus : colorPlus
            updatePriceLabel(to: String.init(format: "%.2f", rightElement.close), in: colorOfPriceLabel)
        } else {
            updatePriceLabel(to: "-", in: .black)
        }
        
    }
    
    private func updatePriceLabel(to newText: String, in color: UIColor) {
        UIView.transition(with: priceLabel, duration: 0.2, options: [.beginFromCurrentState, .transitionCrossDissolve], animations: {
            self.priceLabel.text = newText
            self.priceLabel.textColor = color
        }, completion: nil)
        
    }
    
}
