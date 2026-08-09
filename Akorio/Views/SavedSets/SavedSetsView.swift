//
//  SavedSetsView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI
import SwiftData

struct SavedSetsView: View {
    let viewModel: AppViewModel

    @Query(sort: \SavedChordSet.createdAt, order: .reverse)
    private var savedSets: [SavedChordSet]

    @State private var editingSet: SavedChordSet?
    @State private var editingName = ""
    @State private var pendingDelete: SavedChordSet?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if savedSets.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 10) {
                        ForEach(savedSets) { savedSet in
                            row(for: savedSet)
                        }
                    }
                }
            }
            .padding(20)
        }
        .confirmationDialog(
            String(format: String(localized: "\"%@\" silinsin mi?"), pendingDelete?.name ?? ""),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { isPresented in if !isPresented { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Sil", role: .destructive) {
                if let pendingDelete {
                    viewModel.deleteSavedSet(pendingDelete)
                }
                pendingDelete = nil
            }
            Button("Vazgeç", role: .cancel) { pendingDelete = nil }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.goBack()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(AkorioIconButtonStyle())

            Text("Kayıtlı Setler")
                .font(.akorioSerif(24, .semibold))
                .foregroundColor(.akorioText)
        }
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "music.note.list")
                .font(.akorio(34))
                .foregroundColor(.akorioNeutral600)
            Text("Pratik ekranında akor seçip kaydettiğinde yeni setler burada listelenir.")
                .font(.akorio(13))
                .foregroundColor(.akorioNeutral500)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Row
    private func row(for savedSet: SavedChordSet) -> some View {
        HStack(spacing: 10) {
            if editingSet === savedSet {
                TextField("Set adı", text: $editingName)
                    .font(.akorio(15, .medium))
                    .foregroundColor(.akorioText)
                    .textFieldStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(savedSet.name)
                        .font(.akorio(16, .medium))
                        .foregroundColor(.akorioText)
                    Text(savedSet.subtitle)
                        .font(.akorio(13))
                        .foregroundColor(.akorioNeutral500)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                if editingSet === savedSet {
                    Button {
                        viewModel.renameSavedSet(savedSet, to: editingName)
                        editingSet = nil
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(AkorioIconButtonStyle(size: 32))

                    Button {
                        editingSet = nil
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(AkorioIconButtonStyle(size: 32))
                } else {
                    Button {
                        editingSet = savedSet
                        editingName = savedSet.name
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(AkorioIconButtonStyle(size: 32))

                    Button {
                        pendingDelete = savedSet
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(AkorioIconButtonStyle(size: 32))
                }
            }
        }
        .akorioCard()
        .contentShape(Rectangle())
        .onTapGesture {
            guard editingSet == nil else { return }
            viewModel.loadSavedSet(savedSet)
        }
    }
}

#Preview {
    ZStack {
        AkorioBackground()
        SavedSetsView(viewModel: AppViewModel())
    }
    .modelContainer(for: [SavedChordSet.self, AppSettings.self], inMemory: true)
}
