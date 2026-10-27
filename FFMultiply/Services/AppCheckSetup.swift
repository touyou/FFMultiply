//
//  AppCheckSetup.swift
//  FFMultiply
//
//  Firebase App Check の設定。ランキングへの書き込みが本物のアプリからだと
//  サーバ側で確かめられるようにする（App Attest）。
//

import DeviceCheck
import FirebaseAppCheck
import FirebaseCore

/// App Attest でトークンを作る。App Attest に対応しない実機では DeviceCheck、
/// シミュレータではデバッグ用プロバイダに切り替える。
final class FFAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> (any AppCheckProvider)? {
        #if targetEnvironment(simulator)
        // 起動ログに出るデバッグトークンを Firebase コンソールに登録すると通るようになる。
        return AppCheckDebugProvider(app: app)
        #else
        // DeviceCheck は Firebase に DeviceCheck キーを登録しておかないと通らない。
        if DCAppAttestService.shared.isSupported {
            return AppAttestProvider(app: app)
        }
        return DeviceCheckProvider(app: app)
        #endif
    }
}
