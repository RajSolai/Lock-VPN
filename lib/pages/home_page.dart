import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? curr;
  late OpenVPN openvpn;
  late String country;
  bool isLoading = false;
  String uploaded = "";
  String downloaded = "";
  bool isConnected = false;

  late BannerAd myBanner;

  final BannerAdListener listener = BannerAdListener(
    // Called when an ad is successfully received.
    onAdLoaded: (Ad ad) => print('Ad loaded.'),
    // Called when an ad request failed.
    onAdFailedToLoad: (Ad ad, LoadAdError error) {
      // Dispose the ad here to free resources.
      ad.dispose();
      print('Ad failed to load: $error');
    },
    // Called when an ad opens an overlay that covers the screen.
    onAdOpened: (Ad ad) => print('Ad opened.'),
    // Called when an ad removes an overlay that covers the screen.
    onAdClosed: (Ad ad) => print('Ad closed.'),
    // Called when an impression occurs on the ad.
    onAdImpression: (Ad ad) => print('Ad impression.'),
  );

  @override
  void initState() {
    super.initState();
    country = "india";
    myBanner = BannerAd(
      // adUnitId: 'ca-app-pub-9017472765235373/9838667937',
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: AdRequest(),
      listener: listener,
    );
    myBanner.load();
    openvpn = OpenVPN(
        onVpnStatusChanged: _onVpnStatusChanged,
        onVpnStageChanged: _onVpnStageChanged);
    openvpn.initialize(
        groupIdentifier: "group.io.github.rajsolai.lockVPN.app",
        providerBundleIdentifier: "io.github.rajsolai.lockVPN.app.VPNExtension",
        localizedDescription: "Lock VPN");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    isConnected ? disconnectVpn() : connectVpn();
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10000)),
                    child: Container(
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.height / 15,
                      ),
                      child: isLoading
                          ? CircularProgressIndicator()
                          : Icon(
                              CupertinoIcons.power,
                              color: isConnected
                                  ? Colors.green[200]
                                  : Colors.black,
                              size: 50,
                            ),
                    ),
                  ),
                )
              ],
            )),
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    width: 200,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton(
                            value: country,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(10.0),
                            // underline: Border(),
                            items: [
                              DropdownMenuItem(
                                child: Text("India"),
                                value: "india",
                              ),
                              DropdownMenuItem(
                                child: Text("USA"),
                                value: "usa",
                              )
                            ],
                            onChanged: isConnected
                                ? null
                                : (val) {
                                    country = val.toString();
                                    setState(() {});
                                  }),
                      ),
                    ),
                  ),
                  isConnected
                      ? Expanded(
                          child: Column(
                          children: [
                            Text(
                              "Connected to ${country.toUpperCase()} Server",
                              style: TextStyle(fontSize: 22),
                            ),
                            Text(
                              "Uploaded: $uploaded | Downloaded: $downloaded",
                              style: TextStyle(fontSize: 16),
                            )
                          ],
                        ))
                      : SizedBox.shrink(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      alignment: Alignment.center,
                      child: AdWidget(ad: myBanner),
                      width: myBanner.size.width.toDouble(),
                      height: myBanner.size.height.toDouble(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  connectVpn() async {
    isLoading = true;
    setState(() {});
    if (country == "india") {
      await connectToIndianVpn();
    } else {
      await connectToUSAVpn();
    }
    isLoading = false;
    setState(() {});
  }

  connectToUSAVpn() async {
    var usaConfig = await rootBundle.loadString('assets/usa_client.ovpn');
    openvpn.connect(
      usaConfig,
      "LockVPN",
      username: "openvpn",
      password: "KAAFjEcsAH3JGm",
      bypassPackages: [],
      certIsRequired: true,
    );
  }

  connectToIndianVpn() async {
    var config = await rootBundle.loadString('assets/client.ovpn');
    openvpn.connect(
      config,
      "LockVPN",
      bypassPackages: [],
      certIsRequired: true,
    );
  }

  _onVpnStageChanged(VPNStage? stage, String status) {
    if (stage == VPNStage.connected) {
      isConnected = true;
      isLoading = false;
    } else if (stage == VPNStage.unknown) {
      isLoading = true;
    } else if (stage == VPNStage.vpn_generate_config) {
      isLoading = true;
    } else if (stage == VPNStage.wait_connection) {
      isLoading = true;
    } else if (stage == VPNStage.connecting) {
      isLoading = true;
    } else if (stage == VPNStage.authenticating) {
      isLoading = true;
    } else if (stage == VPNStage.disconnecting) {
      isLoading = true;
    } else if (stage == VPNStage.get_config) {
      isLoading = true;
    } else {
      isConnected = false;
      isLoading = false;
    }
    setState(() {});
    debugPrint(stage.toString());
  }

  _onVpnStatusChanged(VpnStatus? data) {
    debugPrint(data.toString());
    if (data != null) {
      uploaded = data.byteOut ?? "";
      downloaded = data.byteIn ?? "";
      setState(() {});
    }
  }

  disconnectVpn() {
    openvpn.disconnect();
  }
}
