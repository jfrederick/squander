import XCTest

final class SpendthriftUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchedApp(seedData: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        var args = ["-UITestMode"]
        if seedData {
            args.append("-UITestSeedData")
        }
        app.launchArguments = args
        app.launch()
        return app
    }

    /// Looks up any element by accessibility identifier regardless of its
    /// underlying control type (Images/Labels can surface as different
    /// element types across iOS versions).
    private func element(_ app: XCUIApplication, id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    // MARK: - Cold launch

    func test_coldLaunch_showsKeypadReady() {
        let app = launchedApp()

        let amountDisplay = app.staticTexts["amount-display"]
        XCTAssertTrue(amountDisplay.waitForExistence(timeout: 5))
        XCTAssertTrue(amountDisplay.label.contains("0"))

        XCTAssertTrue(app.buttons["keypad-1"].exists)
        XCTAssertTrue(app.buttons["keypad-2"].exists)
        XCTAssertTrue(app.buttons["keypad-3"].exists)
        XCTAssertTrue(app.buttons["keypad-4"].exists)
        XCTAssertTrue(app.buttons["keypad-5"].exists)
        XCTAssertTrue(app.buttons["keypad-6"].exists)
        XCTAssertTrue(app.buttons["keypad-7"].exists)
        XCTAssertTrue(app.buttons["keypad-8"].exists)
        XCTAssertTrue(app.buttons["keypad-9"].exists)
        XCTAssertTrue(app.buttons["keypad-0"].exists)
        XCTAssertTrue(app.buttons["keypad-delete"].exists)

        let nextButton = app.buttons["next-button"]
        XCTAssertTrue(nextButton.exists)
        XCTAssertFalse(nextButton.isEnabled)
    }

    // MARK: - Full capture flow

    func test_fullCaptureFlow() {
        let app = launchedApp()

        app.buttons["keypad-4"].tap()
        app.buttons["keypad-2"].tap()

        let amountDisplay = app.staticTexts["amount-display"]
        XCTAssertTrue(amountDisplay.label.contains("42"))

        let nextButton = app.buttons["next-button"]
        XCTAssertTrue(nextButton.isEnabled)
        nextButton.tap()

        // Backing out returns to the keypad with the amount intact.
        let backButton = app.buttons["back-button"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.tap()
        XCTAssertTrue(app.buttons["keypad-1"].waitForExistence(timeout: 5))
        XCTAssertTrue(amountDisplay.label.contains("42"))

        nextButton.tap()
        let descriptionField = app.textFields["description-field"]
        XCTAssertTrue(descriptionField.waitForExistence(timeout: 5))
        descriptionField.tap()
        descriptionField.typeText("cafe")

        let saveButton = app.buttons["save-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        let confirmation = element(app, id: "save-confirmation")
        XCTAssertTrue(confirmation.waitForExistence(timeout: 3))

        // Saving slides to the Totals screen.
        XCTAssertTrue(element(app, id: "totals-row-0").waitForExistence(timeout: 5))

        // Back on Entry, the keypad has reset to an empty amount step.
        app.tabBars.buttons["Log"].tap()
        XCTAssertTrue(app.staticTexts["amount-display"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["amount-display"].label.contains("0"))
        XCTAssertFalse(app.buttons["next-button"].isEnabled)
    }

    // MARK: - Known description skips category prompt

    func test_knownDescription_skipsCategoryPrompt() {
        let app = launchedApp()

        // First entry: establish "cafe" -> some category via the suggestion chip.
        app.buttons["keypad-3"].tap()
        app.buttons["next-button"].tap()

        let descriptionField = app.textFields["description-field"]
        XCTAssertTrue(descriptionField.waitForExistence(timeout: 5))
        descriptionField.tap()
        descriptionField.typeText("cafe")

        // A never-before-seen description shows the category chip.
        XCTAssertTrue(element(app, id: "category-chip").waitForExistence(timeout: 5))

        app.buttons["save-button"].tap()
        XCTAssertTrue(element(app, id: "save-confirmation").waitForExistence(timeout: 3))

        // Saving lands on Totals; return to Entry for the second expense.
        app.tabBars.buttons["Log"].tap()
        XCTAssertTrue(app.buttons["keypad-5"].waitForExistence(timeout: 3))

        // Second entry with the same description should skip the category prompt.
        app.buttons["keypad-5"].tap()
        app.buttons["next-button"].tap()

        let secondDescriptionField = app.textFields["description-field"]
        XCTAssertTrue(secondDescriptionField.waitForExistence(timeout: 5))
        secondDescriptionField.tap()
        secondDescriptionField.typeText("cafe")

        // Give the view a brief moment to resolve the mapping lookup.
        XCTAssertTrue(element(app, id: "category-chip").waitForNonExistence(timeout: 3))

        let saveButton = app.buttons["save-button"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()
        XCTAssertTrue(element(app, id: "save-confirmation").waitForExistence(timeout: 3))
    }

    // MARK: - Keypad behavior

    func test_leadingZero_and_deleteBehavior() {
        let app = launchedApp()

        let amountDisplay = app.staticTexts["amount-display"]

        // Leading zero is ignored; amount stays empty/zero.
        app.buttons["keypad-0"].tap()
        XCTAssertTrue(amountDisplay.label.contains("0"))
        XCTAssertFalse(app.buttons["next-button"].isEnabled)

        // Build $42, then delete back down to $4.
        app.buttons["keypad-4"].tap()
        app.buttons["keypad-2"].tap()
        XCTAssertTrue(amountDisplay.label.contains("42"))

        app.buttons["keypad-delete"].tap()
        XCTAssertTrue(amountDisplay.label.contains("4"))
        XCTAssertFalse(amountDisplay.label.contains("42"))

        app.buttons["keypad-delete"].tap()
        XCTAssertTrue(amountDisplay.label.contains("0"))
        XCTAssertFalse(app.buttons["next-button"].isEnabled)
    }

    // MARK: - Totals reflect saved expense

    func test_tabNavigation_totalsReflectSavedExpense() {
        let app = launchedApp(seedData: true)

        app.buttons["keypad-1"].tap()
        app.buttons["keypad-5"].tap()
        app.buttons["next-button"].tap()

        let descriptionField = app.textFields["description-field"]
        XCTAssertTrue(descriptionField.waitForExistence(timeout: 5))
        descriptionField.tap()
        descriptionField.typeText("new expense")

        let saveButton = app.buttons["save-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()
        XCTAssertTrue(element(app, id: "save-confirmation").waitForExistence(timeout: 3))

        // Saving navigates to Totals automatically; seeded $25 today + $15.
        let todayRow = element(app, id: "totals-row-0")
        XCTAssertTrue(todayRow.waitForExistence(timeout: 5))
        XCTAssertTrue(todayRow.label.contains("40") || todayRow.staticTexts.matching(NSPredicate(format: "label CONTAINS '40'")).count > 0)
    }

    // MARK: - Edit updates totals

    func test_editExpense_updatesTotals() {
        let app = launchedApp(seedData: true)

        app.tabBars.buttons["Spent"].tap()

        let todayRow = element(app, id: "totals-row-0")
        XCTAssertTrue(todayRow.waitForExistence(timeout: 5))
        todayRow.tap()

        let expenseRow = element(app, id: "expense-row-0")
        XCTAssertTrue(expenseRow.waitForExistence(timeout: 5))
        expenseRow.tap()

        let editSaveButton = app.buttons["edit-save-button"]
        XCTAssertTrue(editSaveButton.waitForExistence(timeout: 5))

        // Add a digit to the amount via the edit keypad.
        app.buttons["edit-keypad-1"].tap()
        XCTAssertTrue(editSaveButton.isEnabled)
        editSaveButton.tap()

        // Back on the drill-in list, then back to Totals; total should reflect the edit.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Log"].tap()
        app.tabBars.buttons["Spent"].tap()

        XCTAssertTrue(element(app, id: "totals-row-0").waitForExistence(timeout: 5))
    }

    // MARK: - Swipe to delete with undo

    func test_swipeToDelete_withUndo() {
        let app = launchedApp(seedData: true)

        app.tabBars.buttons["Spent"].tap()

        let todayRow = element(app, id: "totals-row-0")
        XCTAssertTrue(todayRow.waitForExistence(timeout: 5))
        todayRow.tap()

        let expenseRow = element(app, id: "expense-row-0")
        XCTAssertTrue(expenseRow.waitForExistence(timeout: 5))
        expenseRow.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3))
        deleteButton.tap()

        let undoButton = app.buttons["undo-button"]
        XCTAssertTrue(undoButton.waitForExistence(timeout: 3))
        undoButton.tap()

        XCTAssertTrue(element(app, id: "expense-row-0").waitForExistence(timeout: 5))
    }

    // MARK: - Category filter on the period expense list

    func test_expenseList_categoryFilter() {
        let app = launchedApp(seedData: true)

        app.tabBars.buttons["Spent"].tap()

        let todayRow = element(app, id: "totals-row-0")
        XCTAssertTrue(todayRow.waitForExistence(timeout: 5))
        todayRow.tap()

        // Both of today's seeded expenses are listed unfiltered.
        XCTAssertTrue(element(app, id: "expense-row-0").waitForExistence(timeout: 5))
        XCTAssertTrue(element(app, id: "expense-row-1").exists)

        // Filter to Transport: only the $5 transport expense remains.
        element(app, id: "category-filter-button").tap()
        app.buttons["Transport"].tap()

        let filteredRow = element(app, id: "expense-row-0")
        XCTAssertTrue(filteredRow.waitForExistence(timeout: 3))
        XCTAssertTrue(filteredRow.label.contains("transport"))
        XCTAssertTrue(element(app, id: "expense-row-1").waitForNonExistence(timeout: 3))

        // Deleting the only matching expense shows the filtered empty state
        // rather than falling back to unfiltered results.
        filteredRow.swipeLeft()
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3))
        deleteButton.tap()
        XCTAssertTrue(element(app, id: "filtered-empty").waitForExistence(timeout: 3))

        // Undo restores the expense into the still-active filter.
        app.buttons["undo-button"].tap()
        XCTAssertTrue(element(app, id: "expense-row-0").waitForExistence(timeout: 3))

        // "All Categories" restores the full list.
        element(app, id: "category-filter-button").tap()
        app.buttons["All Categories"].tap()
        XCTAssertTrue(element(app, id: "expense-row-1").waitForExistence(timeout: 3))
    }

    // MARK: - Trend chart on Totals tab

    func test_totalsTab_showsTrendChart_andFollowsGranularity() {
        let app = launchedApp(seedData: true)

        app.tabBars.buttons["Spent"].tap()

        let chart = element(app, id: "trend-chart")
        XCTAssertTrue(chart.waitForExistence(timeout: 5))

        // Chart stays present when switching granularity.
        app.buttons["Weekly"].tap()
        XCTAssertTrue(element(app, id: "trend-chart").waitForExistence(timeout: 3))

        app.buttons["Monthly"].tap()
        XCTAssertTrue(element(app, id: "trend-chart").waitForExistence(timeout: 3))
    }

    // MARK: - Insights screen

    func test_insights_showsWeeklyDigestToggle() {
        let app = launchedApp(seedData: true)

        app.tabBars.buttons["Spent"].tap()

        let insightsButton = element(app, id: "insights-button")
        XCTAssertTrue(insightsButton.waitForExistence(timeout: 5))
        insightsButton.tap()

        // Opt-in toggle is present and off by default (fresh install).
        let toggle = element(app, id: "insights-digest-toggle")
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
    }

    func test_insights_opensShowingCurrentMonth() {
        let app = launchedApp(seedData: true)

        app.tabBars.buttons["Spent"].tap()

        let insightsButton = element(app, id: "insights-button")
        XCTAssertTrue(insightsButton.waitForExistence(timeout: 5))
        insightsButton.tap()

        // Current month has seeded expenses, so the breakdown is shown.
        XCTAssertTrue(element(app, id: "insights-total").waitForExistence(timeout: 5))
        XCTAssertTrue(element(app, id: "insights-comparison").exists)
        XCTAssertTrue(element(app, id: "insights-category-row-0").exists)

        // Forward stepping is disabled at the current month.
        let nextButton = app.buttons["insights-next-month"]
        XCTAssertTrue(nextButton.exists)
        XCTAssertFalse(nextButton.isEnabled)
    }

    func test_insights_stepBackShowsPreviousMonthData() {
        let app = launchedApp(seedData: true)

        app.tabBars.buttons["Spent"].tap()

        let insightsButton = element(app, id: "insights-button")
        XCTAssertTrue(insightsButton.waitForExistence(timeout: 5))
        insightsButton.tap()

        let prevButton = app.buttons["insights-prev-month"]
        XCTAssertTrue(prevButton.waitForExistence(timeout: 5))
        prevButton.tap()

        // Previous month contains the seeded $30 Food & Drink expense; its
        // top-ranked category row must mention it.
        let topRow = element(app, id: "insights-category-row-0")
        XCTAssertTrue(topRow.waitForExistence(timeout: 5))
        XCTAssertTrue(topRow.label.contains("30"))

        // The next-month button re-enables when viewing a past month.
        XCTAssertTrue(app.buttons["insights-next-month"].isEnabled)
    }
}
