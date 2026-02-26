import 'package:flutter/material.dart';
// import 'package:ar_flutter_plugin_plus/ar_flutter_plugin_plus.dart';
// import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
// import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
// import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
// import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
// import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
// import 'package:ar_flutter_plugin_plus/datatypes/hittest_result_types.dart';
// import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
// import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
// import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
// import 'package:ar_flutter_plugin_plus/models/ar_hittest_result.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:flutter/foundation.dart';
import 'package:reality_cart/l10n/app_localizations.dart';

class ARViewScreen extends StatefulWidget {
  final String modelUrl;

  const ARViewScreen({super.key, required this.modelUrl});

  @override
  State<ARViewScreen> createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  // ARSessionManager? arSessionManager;
  // ARObjectManager? arObjectManager;
  // ARAnchorManager? arAnchorManager;
  //
  // List<ARNode> nodes = [];
  // List<ARAnchor> anchors = [];

  bool _isSupported = true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.iOS && defaultTargetPlatform != TargetPlatform.android)) {
      _isSupported = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (_isSupported) {
      // arSessionManager?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color orangeColor = Color(0xFFFB8C00);

    if (!_isSupported) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.arView, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: orangeColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videogame_asset_off, size: 80, color: theme.disabledColor),
              const SizedBox(height: 20),
              Text(AppLocalizations.of(context)!.arNotSupported, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.arView, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: orangeColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // ARView(
          //   onARViewCreated: onARViewCreated,
          //   planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          // ),
          // Overlay removed
        ],
      ),
    );
  }

  // void onARViewCreated(
  //   ARSessionManager arSessionManager,
  //   ARObjectManager arObjectManager,
  //   ARAnchorManager arAnchorManager,
  //   ARLocationManager arLocationManager,
  // ) {
  //   this.arSessionManager = arSessionManager;
  //   this.arObjectManager = arObjectManager;
  //   this.arAnchorManager = arAnchorManager;
  //
  //   this.arSessionManager!.onInitialize(
  //         showFeaturePoints: false,
  //         showPlanes: false,
  //         showWorldOrigin: false,
  //         handleTaps: true,
  //       );
  //   this.arObjectManager!.onInitialize();
  //
  //   this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTap;
  // }

//   Future<void> onPlaneOrPointTap(List<ARHitTestResult> hitTestResults) async {
//     var singleHitTestResult = hitTestResults.firstWhere(
//       (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane,
//     );
//
//     if (singleHitTestResult != null) {
//       var newAnchor = ARPlaneAnchor(
//         transformation: singleHitTestResult.worldTransform,
//       );
//       bool? didAddAnchor = await arAnchorManager!.addAnchor(newAnchor);
//       if (didAddAnchor!) {
//         anchors.add(newAnchor);
//         var newNode = ARNode(
//           type: NodeType.webGLB,
//           uri: widget.modelUrl,
//           scale: vector.Vector3(0.5, 0.5, 0.5),
//           position: vector.Vector3(0.0, 0.0, 0.0),
//           rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),
//         );
//         bool? didAddNodeToAnchor = await arObjectManager!.addNode(newNode, planeAnchor: newAnchor);
//         if (didAddNodeToAnchor!) {
//           nodes.add(newNode);
//         } else {
//           arSessionManager!.onError("Adding Node to Anchor failed");
//         }
//       } else {
//         arSessionManager!.onError("Adding Anchor failed");
//       }
//     }
//   }
// }
}
