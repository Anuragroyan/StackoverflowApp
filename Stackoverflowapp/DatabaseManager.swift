//
//  DatabaseManager.swift
//  Stackoverflowapp
//
//  Created by Dungeon_master on 27/06/25.
//

import Foundation
import SQLite
import SwiftUI



class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: Connection?

    private let table = Table("users")

    private let id = Expression<String>("id")
    private let name = Expression<String>("name")
    private let age = Expression<String>("age")
    private let email = Expression<String>("email")
    private let question = Expression<String>("question")
    private let answers = Expression<String>("answers")
    private let tags = Expression<String>("tags")  // JSON string

    private init() {
        _ = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!

        do {
            db = try Connection("/Users/anuragroy/Desktop/Swift_Projects/Stackoverflowapp/stackoverflow.sqlite3")
            try createTable()
        } catch {
            db = nil
            print("❌ Database connection failed: \(error)")
        }
    }

    // MARK: - Table Setup
    private func createTable() throws {
        try db?.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(name)
            t.column(age)
            t.column(email)
            t.column(question)
            t.column(answers)
            t.column(tags)
        })
    }

    // MARK: - Create
    func insertUser(row: TableRow) {
        let encodedTags = encodeTags(row.tags)

        let insert = table.insert(or: .replace,
                                  id <- row.id.uuidString,
                                  name <- row.name,
                                  age <- row.age,
                                  email <- row.email,
                                  question <- row.question,
                                  answers <- row.answers,
                                  tags <- encodedTags)

        do {
            try db?.run(insert)
            print("✅ Inserted: \(row.name)")
        } catch {
            print("❌ Insert failed: \(error)")
        }
    }

    // MARK: - Read
    func fetchUsers() -> [TableRow] {
        var users: [TableRow] = []
        do {
            for user in try db!.prepare(table) {
                if let uuid = UUID(uuidString: user[id]) {
                    users.append(TableRow(
                        id: uuid,
                        name: user[name],
                        age: user[age],
                        email: user[email],
                        question: user[question],
                        answers: user[answers],
                        tags: decodeTags(user[tags])
                    ))
                }
            }
        } catch {
            print("❌ Fetch failed: \(error)")
        }
        return users
    }

    // MARK: - Update
    func updateUser(_ row: TableRow) {
        let user = table.filter(id == row.id.uuidString)
        let encodedTags = encodeTags(row.tags)
        do {
            try db?.run(user.update(
                name <- row.name,
                age <- row.age,
                email <- row.email,
                question <- row.question,
                answers <- row.answers,
                tags <- encodedTags
            ))
            print("✅ Updated: \(row.name)")
        } catch {
            print("❌ Update failed: \(error)")
        }
    }

    // MARK: - Delete
    func deleteUser(by idValue: UUID) {
        let user = table.filter(id == idValue.uuidString)
        do {
            try db?.run(user.delete())
            print("🗑️ Deleted user with id \(idValue)")
        } catch {
            print("❌ Delete failed: \(error)")
        }
    }

    // MARK: - Search
    func searchUsers(query: String) -> [TableRow] {
        let likeQuery = "%\(query.lowercased())%"
        let filtered = table.filter(
            name.lowercaseString.like(likeQuery) ||
            email.lowercaseString.like(likeQuery) ||
            age.like(likeQuery) ||
            question.lowercaseString.like(likeQuery) ||
            answers.lowercaseString.like(likeQuery) ||
            tags.like(likeQuery)
        )

        var results: [TableRow] = []

        do {
            for user in try db!.prepare(filtered) {
                if let uuid = UUID(uuidString: user[id]) {
                    results.append(TableRow(
                        id: uuid,
                        name: user[name],
                        age: user[age],
                        email: user[email],
                        question: user[question],
                        answers: user[answers],
                        tags: decodeTags(user[tags])
                    ))
                }
            }
        } catch {
            print("❌ Search failed: \(error)")
        }

        return results
    }

    // MARK: - Helpers for Tags
    private func encodeTags(_ tagsArray: [String]) -> String {
        let validTags = Array(tagsArray.prefix(5))  // Enforce max 5
        let data = try? JSONSerialization.data(withJSONObject: validTags, options: [])
        return String(data: data ?? Data(), encoding: .utf8) ?? "[]"
    }

    private func decodeTags(_ tagsString: String) -> [String] {
        guard let data = tagsString.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [String]
        else { return [] }
        return array
    }
}
