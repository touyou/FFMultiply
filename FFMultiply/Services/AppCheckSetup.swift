//
//  AppCheckSetup.swift
//  FFMultiply
//
//  Firebase App Check の設定。ランキングへの書き込みが本物のアプリからだと
//  サーバ側で確かめられるようにする（App Attest）。
//

import FirebaseAppCheck
import FirebaseCore

/// App Attest でトークンを作る。App Attest が使えない端末（シミュレータ）では
/// デバッグ用プロバイダに切り替える。
final class FFAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> (any AppCheckProvider)? {
        #if targetEnvironment(simulator)
        // 起動ログに出るデバッグトークンを Firebase コンソールに登録すると通るようになる。
        return AppCheckDebugProvider(app: app)
        #else
        return AppAttestProvider(app: app)
        #endif
    }
}
