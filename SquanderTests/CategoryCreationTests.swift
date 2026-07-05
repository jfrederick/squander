import Foundation
import SwiftData
import Testing
import SquanderCore
@testable import Squander

@MainActor
struct CategoryCreationTests {
    @Test func createCategorySucceeds() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()

        let pets = try store.createCategory(named: "Pets")
        #expect(pets.name == "Pets")
        #expect(pets.isSeeded == false)

        let categories = try store.allCategories()
        #expect(categories.count == 13)
        #expect(categories.map(\.name).contains("Pets"))
    }

    @Test func createCategoryRejectsDuplicateNameAnyCase() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()

        #expect(throws: ExpenseStore.CategoryCreationError.duplicateName) {
            try store.createCategory(named: "food & drink")
        }
        #expect(throws: ExpenseStore.CategoryCreationError.duplicateName) {
            try store.createCategory(named: "FOOD & DRINK")
        }
    }

    @Test func createCategoryRejectsWhitespaceOnlyName() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()

        #expect(throws: ExpenseStore.CategoryCreationError.invalidName) {
            try store.createCategory(named: "   ")
        }
    }

    @Test func createCategoryRefusedAtCap() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()

        // 12 seeded already exist; create up to the 30-category cap.
        let existing = try store.allCategories().count
        #expect(existing == 12)
        for i in 0..<(CategoryRules.maxCount - existing) {
            try store.createCategory(named: "Custom \(i)")
        }

        let total = try store.allCategories().count
        #expect(total == CategoryRules.maxCount)

        #expect(throws: ExpenseStore.CategoryCreationError.capReached) {
            try store.createCategory(named: "One Too Many")
        }
    }
}
