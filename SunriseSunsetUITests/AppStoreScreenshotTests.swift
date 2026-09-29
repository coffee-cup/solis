import XCTest

final class AppStoreScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppStoreScreenshots() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["6:50 pm"].waitForExistence(timeout: 10))
        capture("01-timeline")

        openSettings(app)
        app.buttons["locationRow"].tap()
        XCTAssertTrue(app.navigationBars["Location"].waitForExistence(timeout: 5))
        XCTAssertGreaterThan(app.navigationBars["Location"].frame.minY, app.frame.height * 0.4)
        XCTAssertTrue(app.descendants(matching: .any)["Tokyo, Japan"].exists)
        capture("03-locations")

        app.terminate()
        let ember = launch(ember: true)
        openSettings(ember)
        ember.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Theme,")).firstMatch.tap()
        XCTAssertTrue(ember.buttons["Infrared"].waitForExistence(timeout: 5))
        XCTAssertGreaterThan(ember.navigationBars["Theme"].frame.minY, ember.frame.height * 0.4)
        capture("02-themes")

        ember.terminate()
        let classic = launch()
        openSettings(classic, expanded: true)
        XCTAssertEqual(classic.switches["Sunrise"].value as? String, "1")
        XCTAssertEqual(classic.switches["Sunset"].value as? String, "1")
        for name in ["First Light", "Last Light"] {
            XCTAssertEqual(classic.switches[name].value as? String, "0")
        }
        capture("04-alerts")
    }

    @MainActor
    func testFixtureDoesNotPersist() {
        let fixture = launch()
        fixture.terminate()
        let normal = XCUIApplication()
        normal.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_CA"]
        normal.launch()
        XCTAssertTrue(normal.staticTexts["I need a location to do anything 🌎"].waitForExistence(timeout: 10))
    }

    @MainActor
    private func launch(ember: Bool = false) -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = [
            "--app-store-screenshots", "-AppleLanguages", "(en)", "-AppleLocale", "en_CA",
            "-AppleInterfaceStyle", "Light",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryM",
        ]
        if ember { app.launchArguments.append("--screenshot-ember") }
        app.launchEnvironment["TZ"] = "America/Vancouver"
        app.launch()
        XCTAssertTrue(app.buttons["settings"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor
    private func openSettings(_ app: XCUIApplication, expanded: Bool = false) {
        app.buttons["settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        if expanded {
            app.swipeUp()
            XCTAssertTrue(app.buttons["Learn"].waitForExistence(timeout: 5))
        }
    }

    @MainActor
    private func capture(_ name: String) {
        Thread.sleep(forTimeInterval: 1)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "appstore-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
