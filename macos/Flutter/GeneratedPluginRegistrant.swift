//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import connectivity_plus
import device_info_plus
import flutter_secure_storage_darwin
import geolocator_apple
import local_auth_darwin
import package_info_plus
import printing
import webview_flutter_wkwebview

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  ConnectivityPlusPlugin.register(with: registry.registrar(forPlugin: "ConnectivityPlusPlugin"))
  DeviceInfoPlusMacosPlugin.register(with: registry.registrar(forPlugin: "DeviceInfoPlusMacosPlugin"))
  FlutterSecureStorageDarwinPlugin.register(with: registry.registrar(forPlugin: "FlutterSecureStorageDarwinPlugin"))
  GeolocatorPlugin.register(with: registry.registrar(forPlugin: "GeolocatorPlugin"))
  LocalAuthPlugin.register(with: registry.registrar(forPlugin: "LocalAuthPlugin"))
  FPPPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
  PrintingPlugin.register(with: registry.registrar(forPlugin: "PrintingPlugin"))
  WebViewFlutterPlugin.register(with: registry.registrar(forPlugin: "WebViewFlutterPlugin"))
}
