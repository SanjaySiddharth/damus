//
//  RelayPicView.swift
//  damus
//
//  Created by eric on 9/2/23.
//

import SwiftUI
import Kingfisher
import TLDExtract

struct FailedRelayImage: View {
    let url: URL?

    var body: some View {
        let abbrv = String(url?.hostname?.first?.uppercased() ?? "R")
        Text("\(abbrv)")
            .font(.system(size: 40, weight: .bold))
    }
}

struct InnerRelayPicView: View {
    let url: URL?
    let size: CGFloat
    let highlight: Highlight
    let disable_animation: Bool
    @State var failedImage: Bool = false

    func Placeholder(url: URL?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .frame(width: size, height: size)
                .foregroundColor(DamusColors.adaptableGrey)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(highlight_color(highlight), lineWidth: pfp_line_width(highlight)))
                .padding(2)

            FailedRelayImage(url: url)
        }
    }

    var body: some View {
        ZStack {
            Color(uiColor: .secondarySystemBackground)

            if let url {
                KFAnimatedImage(url)
                    .imageContext(.pfp, disable_animation: disable_animation)
                    .onFailure { _ in
                        failedImage = true
                    }
                    .cancelOnDisappear(true)
                    .configure { view in
                        view.framePreloadCount = 3
                    }
                    .placeholder { _ in
                        Placeholder(url: url)
                    }
                    .scaledToFit()
            } else {
                FailedRelayImage(url: nil)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(failedImage ? .gray : highlight_color(highlight), lineWidth: failedImage ? 1 : pfp_line_width(highlight)))
    }
}

struct RelayPicView: View {
    let relay: String
    let icon: String?
    let size: CGFloat
    let highlight: Highlight
    let disable_animation: Bool
    
    init(relay: String, icon: String? = nil, size: CGFloat, highlight: Highlight, disable_animation: Bool) {
        self.relay = relay
        self.icon = icon
        self.size = size
        self.highlight = highlight
        self.disable_animation = disable_animation
    }

    var relay_url: URL? {
        get_relay_url(relay: relay, icon: icon)
    }
    
    var body: some View {
        InnerRelayPicView(url: relay_url, size: size, highlight: highlight, disable_animation: disable_animation)
    }
}

func get_relay_url(relay: String, icon: String?) -> URL? {
    let extractor = TLDExtract()
    var favicon = relay + "/favicon.ico"
    if let parseRelay: TLDResult = extractor.parse(relay) {
        favicon = "https://" + (parseRelay.rootDomain ?? relay) + "/favicon.ico"
    }
    let pic = icon ?? favicon
    return URL(string: pic)
}

struct RelayPicView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RelayPicView(relay: "wss://relay.damus.io", size: 55, highlight: .none, disable_animation: false)
            RelayPicView(relay: "wss://nostr.wine", size: 55, highlight: .none, disable_animation: false)
            RelayPicView(relay: "wss://nos.lol", size: 55, highlight: .none, disable_animation: false)
            RelayPicView(relay: "fail", size: 55, highlight: .none, disable_animation: false)
        }
    }
}

