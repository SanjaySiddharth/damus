//
//  SearchHomeView.swift
//  damus
//
//  Created by William Casarin on 2022-05-19.
//

import SwiftUI
import CryptoKit
import NaturalLanguage

struct SearchHomeView: View {
    let damus_state: DamusState
    @StateObject var model: SearchHomeModel
    @State var search: String = ""
    @FocusState private var isFocused: Bool

    var content_filter: (NostrEvent) -> Bool {
        let filters = ContentFilters.defaults(damus_state: self.damus_state)
        return ContentFilters(filters: filters).filter
    }

    var SearchInput: some View {
        HStack {
            HStack{
                Image("search")
                    .foregroundColor(.gray)
                TextField(NSLocalizedString("Search...", comment: "Placeholder text to prompt entry of search query."), text: $search)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)
            }
            .padding(10)
            .background(.secondary.opacity(0.2))
            .cornerRadius(20)
            
            if(!search.isEmpty) {
                Text("Cancel", comment: "Cancel out of search view.")
                    .foregroundColor(.accentColor)
                    .padding(EdgeInsets(top: 0.0, leading: 0.0, bottom: 0.0, trailing: 10.0))
                    .onTapGesture {
                        self.search = ""
                        isFocused = false
                    }
            }
        }
    }
    
    var GlobalContent: some View {
        return TimelineView<AnyView>(
            events: model.events,
            loading: $model.loading,
            damus: damus_state,
            show_friend_icon: true,
            filter: { ev in
                if !content_filter(ev) {
                    return false
                }
                
                let event_muted = damus_state.mutelist_manager.is_event_muted(ev)
                if event_muted {
                    return false
                }

                return true
            },
            content: {
                AnyView(VStack {
                    SuggestedHashtagsView(damus_state: damus_state, max_items: 5, events: model.events)
                    
                    Divider()
                        .frame(height: 1)
                    
                    HStack {
                        Image("notes.fill")
                        Text("All recent notes", comment: "A label indicating that the notes being displayed below it are all recent notes")
                        Spacer()
                    }
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
                    .padding(.horizontal)
                }.padding(.bottom, 50))
            }
        )
        .refreshable {
            // Fetch new information by unsubscribing and resubscribing to the relay
            model.unsubscribe()
            model.subscribe()
        }
    }
    
    var SearchContent: some View {
        SearchResultsView(damus_state: damus_state, search: $search)
            .refreshable {
                // Fetch new information by unsubscribing and resubscribing to the relay
                model.unsubscribe()
                model.subscribe()
            }
    }
    
    var MainContent: some View {
        Group {
            if search.isEmpty {
                GlobalContent
            } else {
                SearchContent
            }
        }
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            MainContent
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                SearchInput
                    //.frame(maxWidth: 275)
                    .padding()
                Divider()
                    .frame(height: 1)
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
        .onReceive(handle_notify(.new_mutes)) { _ in
            self.model.filter_muted()
        }
        .onAppear {
            if model.events.events.isEmpty {
                model.subscribe()
            }
        }
        .onDisappear {
            model.unsubscribe()
        }
    }
}

struct SearchHomeView_Previews: PreviewProvider {
    static var previews: some View {
        let state = test_damus_state
        SearchHomeView(damus_state: state, model: SearchHomeModel(damus_state: state))
    }
}
