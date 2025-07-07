//
//  ContentView.swift
//  Stackoverflowapp
//
//  Created by Dungeon_master on 27/06/25.
//

import SwiftUI

// MARK: - TableRow Model
struct TableRow: Identifiable, Equatable {
    let id: UUID
    var name: String
    var age: String
    var email: String
    var question: String
    var answers: String
    var tags: [String] = []
}

// MARK: - Tag Input View
struct TagInputView: View {
    @Binding var tags: [String]
    @State private var tagText: String = ""
    
    var body: some View {
        ZStack{
            Color(.secondarySystemBackground) // 🌟 Your desired background color
                    .ignoresSafeArea()
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField("Add tag...", text: $tagText, onCommit: addTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(tags.count >= 5 ? .gray : .blue)
                        .font(.title2)
                }
                .disabled(tags.count >= 5 || tagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            let columns = [
                GridItem(.adaptive(minimum: 100), spacing: 6)
            ]

            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(tags, id: \.self) { tag in
                    HStack(spacing: 6) {
                        Text(tag)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(20)

                        Button(action: {
                            removeTag(tag)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.trailing, 6)
                    .background(Color.white)
                    .cornerRadius(20)
                }
            }

        }
        .animation(.easeInOut, value: tags)
    }
}
    

    private func addTag() {
        let trimmed = tagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed), tags.count < 5 else { return }
        tags.append(trimmed)
        tagText = ""
    }

    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

// MARK: - WrapHStack for tag layout
struct WrapHStack<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content

    init(spacing: CGFloat = 10, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geometry in
            generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            content()
                .padding(5)
                .background(GeometryReader { geo in
                    Color.clear.onAppear {
                        let itemSize = geo.size
                        if width + itemSize.width > g.size.width {
                            width = 0
                            height += itemSize.height + spacing
                        }
                        width += itemSize.width + spacing
                        DispatchQueue.main.async {
                            self.totalHeight = height + itemSize.height
                        }
                    }
                })
                .alignmentGuide(.leading) { _ in width }
                .alignmentGuide(.top) { _ in height }
        }
    }
}

// MARK: - Dynamic Table View with Form & Tags
struct ContentView: View {
    @State private var allData: [TableRow] = []
    @State private var displayedData: [TableRow] = []
    @State private var searchText: String = ""
    @State private var currentPage: Int = 1
    @State private var name = ""
    @State private var age = ""
    @State private var email = ""
    @State private var question = ""
    @State private var answers = ""
    @State private var tags: [String] = []
    @State private var editingRow: TableRow? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertSuccess = true
    @State private var selectedTagFilters: Set<String> = []

    private let pageSize = 10

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                TextField("Search...", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                // Tag Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(allUniqueTags(), id: \.self) { tag in
                            Button(action: {
                                toggleTagFilter(tag)
                            }) {
                                Text(tag)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedTagFilters.contains(tag) ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedTagFilters.contains(tag) ? .white : .black)
                                    .cornerRadius(20)
                            }
                        }
                    }.padding(.horizontal)
                }
                
                // Table Headers
                HStack {
                    Text("Name").bold()
                    Text("Age").bold()
                    Text("Email").bold()
                    Text("Question").bold()
                    Text("Answers").bold()
                    Text("Tags").bold()
                    Spacer()
                }.padding(.horizontal)
                
                Divider()
                
                ScrollView([.horizontal], showsIndicators: true) {
                    LazyVStack {
                        ForEach(displayedData) { row in
                            if editingRow?.id == row.id {
                                HStack {
                                    TextField("Name", text: Binding(get: { editingRow?.name ?? "" }, set: { editingRow?.name = $0 }))
                                    TextField("Age", text: Binding(get: { editingRow?.age ?? "" }, set: { editingRow?.age = $0 }))
                                    TextField("Email", text: Binding(get: { editingRow?.email ?? "" }, set: { editingRow?.email = $0 }))
                                    TextField("Question", text: Binding(get: { editingRow?.question ?? "" }, set: { editingRow?.question = $0 }))
                                    TextField("Answers", text: Binding(get: { editingRow?.answers ?? "" }, set: { editingRow?.answers = $0 }))
                                    Button("Save") { saveEditedRow() }
                                    Button("Cancel") { editingRow = nil }
                                }.padding(.horizontal)
                            } else {
                                HStack(alignment: .top, spacing: 10) {
                                    Text(row.name)
                                        .frame(minWidth: 80, alignment: .leading)
                                    Text(row.age)
                                        .frame(minWidth: 40, alignment: .leading)
                                    Text(row.email)
                                        .frame(minWidth: 120, alignment: .leading)
                                    Text(row.question)
                                        .frame(minWidth: 150, alignment: .leading)
                                    Text(row.answers)
                                        .frame(minWidth: 150, alignment: .leading)
                                    Text(row.tags.joined(separator: ", "))
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(minWidth: 150, alignment: .leading)
                                    
                                    Button(action: { editingRow = row }) {
                                        Image(systemName: "pencil").foregroundColor(.blue)
                                    }
                                    Button(action: { deleteRow(row) }) {
                                        Image(systemName: "trash").foregroundColor(.red)
                                    }
                                }
                                .padding(.horizontal)
                                
                                .onAppear {
                                    if row.id == displayedData.last?.id {
                                        loadNextPage()
                                    }
                                }
                            }
                            Divider()
                        }
                    }
                }
                
                Divider()
                
                Text("➕ Add New User").font(.headline)
                
                ScrollView {
                    VStack(spacing: 10) {
                        TextField("Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Age", text: $age)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Question", text: $question)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Answers", text: $answers)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TagInputView(tags: $tags)
                        
                        Button("Add Entry") {
                            guard !name.isEmpty, !age.isEmpty, !email.isEmpty,
                                  !question.isEmpty, !answers.isEmpty else { return }
                            
                            let newRow = TableRow(
                                id: UUID(),
                                name: name,
                                age: age,
                                email: email,
                                question: question,
                                answers: answers,
                                tags: tags
                            )
                            DatabaseManager.shared.insertUser(row: newRow)
                            allData.insert(newRow, at: 0)
                            name = ""; age = ""; email = ""; question = ""; answers = ""; tags = []
                            resetPagination()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding()
                }
                
                .padding()
            }
        }
        .onAppear { loadInitialData() }
//        .onChange(of: searchText) { _ in resetPagination() }
//        .onChange(of: selectedTagFilters) { _ in resetPagination() }
        .task(id: searchText) {
                   resetPagination()
               }
               .task(id: selectedTagFilters) {
                   resetPagination()
               }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertSuccess ? "Success" : "Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Helpers

    private func loadInitialData() {
        allData = DatabaseManager.shared.fetchUsers()
        resetPagination()
    }

    private func resetPagination() {
        currentPage = 1
        let filtered = filterData()
        displayedData = Array(filtered.prefix(pageSize))
    }

    private func loadNextPage() {
        let filtered = filterData()
        let start = currentPage * pageSize
        let end = start + pageSize
        if start < filtered.count {
            displayedData.append(contentsOf: filtered[start..<min(end, filtered.count)])
            currentPage += 1
        }
    }

    private func saveEditedRow() {
        guard let updated = editingRow else { return }
        DatabaseManager.shared.updateUser(updated)
        if let index = allData.firstIndex(where: { $0.id == updated.id }) {
            allData[index] = updated
            resetPagination()
        }
        editingRow = nil
        alertSuccess = true
        alertMessage = "User updated successfully."
        showAlert = true
    }

    private func deleteRow(_ row: TableRow) {
        DatabaseManager.shared.deleteUser(by: row.id)
        allData.removeAll { $0.id == row.id }
        resetPagination()
        alertSuccess = true
        alertMessage = "User deleted."
        showAlert = true
    }

    private func toggleTagFilter(_ tag: String) {
        if selectedTagFilters.contains(tag) {
            selectedTagFilters.remove(tag)
        } else {
            selectedTagFilters.insert(tag)
        }
    }

    private func allUniqueTags() -> [String] {
        let allTags = allData.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }

    private func filterData() -> [TableRow] {
        var filtered = searchText.isEmpty ? allData : DatabaseManager.shared.searchUsers(query: searchText)
        if !selectedTagFilters.isEmpty {
            filtered = filtered.filter { !Set($0.tags).isDisjoint(with: selectedTagFilters) }
        }
        return filtered
    }
}

// MARK: - Preview
struct DynamicTableView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
