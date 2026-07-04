//
//  BannerAdView.swift
//  FFMultiply
//
//  GoogleMobileAds v12+ の `BannerView` を SwiftUI で使うための UIViewRepresentable。
//  控えめに標準バナー（320x50 固定）を使い、レイアウトを圧迫しないようにする。
//

import SwiftUI
import GoogleMobileAds

/// 画面下部に置くバナー領域。広告無効時（スクショ/UIテスト）は何も表示しない。
struct AdBannerView: View {
    var body: some View {
        if AdManager.adsDisabled {
            EmptyView()
        } else {
            BannerAdView()
                .frame(width: 320, height: BannerAdView.height)
        }
    }
}

struct BannerAdView: UIViewRepresentable {
    var adUnitID: String = AdManager.bannerAdUnitID

    /// 標準バナーの高さ（レイアウトの高さ指定に使う）。
    static let height: CGFloat = 50

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = AdManager.rootViewController()
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
