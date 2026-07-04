//
//  LocalScoreView.swift
//  FFMultiply
//
//  ローカルスコア一覧（SwiftData）。同点は同順位でランク付けし、上位 50 件を表示。
//  データが無いときは ContentUnavailableView を表示する。
//

import SwiftUI
import SwiftData

struct LocalScoreView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\ScoreEntry.score, order: .reverse),
                  SortDescriptor(\ScoreEntry.date, order: .reverse)]) private var scores: [ScoreEntry]

    @State private var showDeleteConfirm = false

    private let storage = UserDefaults.standard

    /// ランキング表示の 1 行。
    private struct RankedScore: Identifiable {
        let id: PersistentIdentifier
        let rank: Int
        let score: Int
        let date: Date
    }

    /// 同点同順位でランク付けした上位 50 件。
    private var ranked: [RankedScore] {
        var result: [RankedScore] = []
        var currentRank = 0
        var previousScore: Int?
        for (index, entry) in scores.prefix(50).enumerated() {
            if entry.score != previousScore {
                currentRank = index + 1
                previousScore = entry.score
            }
            result.append(RankedScore(id: entry.persistentModelID, rank: currentRank, score: entry.score, date: entry.date))
        }
        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if scores.isEmpty {
                    ContentUnavailableView("No Data", systemImage: "tray")
                        .foregroundStyle(FFColor.white)
                } else {
                    List(ranked) { row in
                        Text("\(row.rank). \(row.score) points\n\t date: \(row.date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.futuraMedium(size: 16))
                            .foregroundStyle(FFColor.white)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FFColor.brown.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Local Score")
                        .font(.futuraBold(size: 17))
                        .foregroundStyle(FFColor.white)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .tint(FFColor.red)
                }
            }
            .alert("delete data", isPresented: $showDeleteConfirm) {
                Button("OK", role: .destructive, action: deleteAll)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Do you really want to delete all your data?")
            }
        }
    }

    private func deleteAll() {
        if let name = storage.object(forKey: "playername") as? String, !name.isEmpty {
            RankingService.shared.reset(name: name)
        }
        ScoreStore(context: modelContext).deleteAll()
    }
}
