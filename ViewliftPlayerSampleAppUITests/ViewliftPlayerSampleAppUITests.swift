//
//  ViewliftPlayerSampleAppUITests.swift
//  ViewliftPlayerSampleAppUITests
//
//  Created by Gaurav Vig on 07/12/21.
//  Copyright © 2021 Viewlift. All rights reserved.
//

import XCTest

class ViewliftPlayerSampleAppUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_VideoPlayback() {
        app.tables.cells.staticTexts["Default sdk controls"].tap()
        addingDelayTextExecution(delayTimeInterval: 10)
    }
    
    func test_VideoPlaybackWithDebugLogEnabled() {
        app.tables.cells.staticTexts["Debug logs enabled"].tap()
        addingDelayTextExecution(delayTimeInterval: 10)
    }
    
    func test_VideoPlaybackWithCustomUIEnabled() {
        app.tables.cells.staticTexts["Custom controls"].tap()
        addingDelayTextExecution(delayTimeInterval: 10)
    }
    
    func test_VideoPlaybackWithCustomUIAndDebugLogEnabled() {
        app.tables.cells.staticTexts["Custom controls and debug logs enabled"].tap()
        addingDelayTextExecution(delayTimeInterval: 10)
    }
    
    func test_VideoPlaybackWithAdsEnabled() {
        app.tables.cells.staticTexts["Ads Enabled"].tap()
        addingDelayTextExecution(delayTimeInterval: 10)
    }
    
    
    func test_VideoPlaybackWithPlayPause() {
        app.tables.cells.staticTexts["Default sdk controls"].tap()
        addingDelayTextExecution(delayTimeInterval: 6)
        
        let mediaplayButton = app.tables.cells.buttons["mediaPlay"]
        if mediaplayButton.exists && mediaplayButton.isHittable {
            mediaplayButton.tap()
            addingDelayTextExecution(delayTimeInterval: 2)
            
            mediaplayButton.tap()
            addingDelayTextExecution(delayTimeInterval: 6)
        }
    }
    
    func test_VideoPlaybackForCustomUIWithPlayPause() {
        app.tables.cells.staticTexts["Custom controls"].tap()
        addingDelayTextExecution(delayTimeInterval: 6)
        
        let mediaplayButton = app.tables.cells.buttons["mediaPlay"]
        if mediaplayButton.exists && mediaplayButton.isHittable {
            mediaplayButton.tap()
            addingDelayTextExecution(delayTimeInterval: 2)
            
            mediaplayButton.tap()
            addingDelayTextExecution(delayTimeInterval: 15)
        }
    }
    
    func test_VideoSeekForward() {
        app.tables.cells.staticTexts["Default sdk controls"].tap()
        addingDelayTextExecution(delayTimeInterval: 6)
        
        let forwardButton = app.tables.cells.buttons["Forward"]
        forwardButton.tap()
        addingDelayTextExecution(delayTimeInterval: 4)
        
        forwardButton.tap()
        addingDelayTextExecution(delayTimeInterval: 6)
    }
    
    func test_VideoSeekBackward() {
        app.tables.cells.staticTexts["Default sdk controls"].tap()
        addingDelayTextExecution(delayTimeInterval: 6)
        
        let rewindButton = app.tables.cells.buttons["RewindButton"]
        rewindButton.tap()
        addingDelayTextExecution(delayTimeInterval: 6)
    }
    
    func test_VideoSeekForwardThenBackward() {
        app.tables.cells.staticTexts["Default sdk controls"].tap()
        addingDelayTextExecution(delayTimeInterval: 6)
        
        let forwardButton = app.tables.cells.buttons["Forward"]
        forwardButton.tap()
        addingDelayTextExecution(delayTimeInterval: 4)
        
        let rewindButton = app.tables.cells.buttons["RewindButton"]
        rewindButton.tap()
        addingDelayTextExecution(delayTimeInterval: 6)
    }
    
    func test_VideoSeekForwardForCustomUI() {
        app.tables.cells.staticTexts["Custom controls and custom seek duration"].tap()
        addingDelayTextExecution(delayTimeInterval: 6)
        
        let forwardButton = app.tables.cells.buttons["Forward"]
        forwardButton.tap()
        addingDelayTextExecution(delayTimeInterval: 4)
        
        forwardButton.tap()
        addingDelayTextExecution(delayTimeInterval: 6)
    }
    
    func test_VideoSeekBackwardForCustomUI() {
        app.tables.cells.staticTexts["Custom controls and custom seek duration"].tap()
        addingDelayTextExecution(delayTimeInterval: 6)
        
        let forwardButton = app.tables.cells.buttons["Forward"]
        forwardButton.tap()
        addingDelayTextExecution(delayTimeInterval: 4)
        
        let rewindButton = app.tables.cells.buttons["RewindButton"]
        rewindButton.tap()
        addingDelayTextExecution(delayTimeInterval: 6)
    }
    
    func test_videoPlaybackSliderSeek() {
        app.tables.cells.staticTexts["Default sdk controls"].tap()
        addingDelayTextExecution(delayTimeInterval: 6)
    
        let sliderSeek70 = app.tables.cells.sliders.firstMatch
        sliderSeek70.adjust(toNormalizedSliderPosition: 0.7)
        addingDelayTextExecution(delayTimeInterval: 4)
        
        let sliderSeek20 = app.tables.cells.sliders.firstMatch
        sliderSeek20.adjust(toNormalizedSliderPosition: 0.2)
        addingDelayTextExecution(delayTimeInterval: 6)
    }

    func test_videoPlaybackWithSubtitlesOn() {
        app.tables.cells.staticTexts["Default sdk controls"].tap()
        addingDelayTextExecution(delayTimeInterval: 6)
        
        let sliderSeek50 = app.tables.cells.sliders.firstMatch
        sliderSeek50.adjust(toNormalizedSliderPosition: 0.5)
        addingDelayTextExecution(delayTimeInterval: 4)
        
        let ccButton = app.tables.cells.buttons["icon cc disable"]
        if ccButton.exists {
            ccButton.tap()
        }
        addingDelayTextExecution(delayTimeInterval: 4)
    }
    
    func test_videoPlaybackWithFullScreenClick() {
        app.tables.cells.staticTexts["Default sdk controls"].tap()
        addingDelayTextExecution(delayTimeInterval: 6)
        
        let sliderSeek50 = app.tables.cells.sliders.firstMatch
        sliderSeek50.adjust(toNormalizedSliderPosition: 0.5)
        addingDelayTextExecution(delayTimeInterval: 4)
        
        let fullScreenButton = app.tables.cells.buttons["Fullscreen"]
        if fullScreenButton.exists {
            fullScreenButton.tap()
        }
        addingDelayTextExecution(delayTimeInterval: 4)
    }

    func test_videoPlaybackWithZoomInOut() {
        app.tables.cells.staticTexts["Default sdk controls"].tap()
        addingDelayTextExecution(delayTimeInterval: 6)

        let sliderSeek50 = app.tables.cells.sliders.firstMatch
        sliderSeek50.adjust(toNormalizedSliderPosition: 0.5)
        addingDelayTextExecution(delayTimeInterval: 2)

        let fullScreenButton = app.tables.cells.buttons["Fullscreen"]
        if fullScreenButton.exists {
            fullScreenButton.tap()
        }

        addingDelayTextExecution(delayTimeInterval: 2)

        let zoomInButton = app.buttons["icon zoomin"]
        if zoomInButton.exists {
            zoomInButton.tap()
        }
        addingDelayTextExecution(delayTimeInterval: 4)

        if zoomInButton.exists {
            zoomInButton.tap()
        }
        addingDelayTextExecution(delayTimeInterval: 4)
    }
    
    private func addingDelayTextExecution(delayTimeInterval:TimeInterval) {
        let delayExecution = XCTestExpectation()
        delayExecution.isInverted = true
        wait(for: [delayExecution], timeout: delayTimeInterval)
    }
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
