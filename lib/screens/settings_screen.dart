import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<Permission, PermissionStatus> _permissionStatuses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.locationWhenInUse,
      Permission.locationAlways,
      Permission.microphone,
      Permission.phone,
      Permission.sms,
      Permission.notification,
    ];

    final statuses = await Future.wait(
      permissions.map((permission) => permission.status),
    );

    if (mounted) {
      setState(() {
        _permissionStatuses = Map.fromIterables(permissions, statuses);
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePermissionChange(Permission permission, bool value) async {
    try {
      PermissionStatus status;
      
      if (value) {
        if (permission == Permission.locationAlways) {
          // For background location, we need to request when-in-use first
          final whenInUse = await Permission.locationWhenInUse.request();
          if (whenInUse.isGranted) {
            status = await permission.request();
          } else {
            status = whenInUse;
          }
        } else {
          status = await permission.request();
        }
      } else {
        // For turning off, direct users to settings
        await openAppSettings();
        return;
      }

      if (mounted) {
        setState(() {
          _permissionStatuses[permission] = status;
        });

        String message;
        if (status.isGranted) {
          message = '${_getPermissionTitle(permission)} enabled';
        } else if (status.isPermanentlyDenied) {
          message = 'Please enable ${_getPermissionTitle(permission)} in settings';
          await openAppSettings();
        } else {
          message = '${_getPermissionTitle(permission)} disabled';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: status.isGranted ? Colors.green : Colors.orange,
            action: status.isPermanentlyDenied ? SnackBarAction(
              label: 'SETTINGS',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ) : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error managing permission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getPermissionTitle(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera';
      case Permission.locationWhenInUse:
        return 'Location (When In Use)';
      case Permission.locationAlways:
        return 'Location (Always)';
      case Permission.microphone:
        return 'Microphone';
      case Permission.phone:
        return 'Phone';
      case Permission.sms:
        return 'SMS';
      case Permission.notification:
        return 'Notifications';
      default:
        return permission.toString();
    }
  }

  String _getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Access camera for taking photos and scanning QR codes';
      case Permission.locationWhenInUse:
        return 'Access location for finding nearby services and weather info';
      case Permission.locationAlways:
        return 'Access location for finding nearby services and weather info';
      case Permission.microphone:
        return 'Access microphone for voice messages and calls';
      case Permission.phone:
        return 'Access phone for making calls and sending SMS messages';
      case Permission.sms:
        return 'Access SMS for sending and receiving messages';
      case Permission.notification:
        return 'Send notifications for updates and messages';
      default:
        return 'Access required for app functionality';
    }
  }

  Icon _getPermissionIcon(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return Icon(Icons.camera_alt, color: Colors.green);
      case Permission.locationWhenInUse:
        return Icon(Icons.location_on, color: Colors.green);
      case Permission.locationAlways:
        return Icon(Icons.location_on, color: Colors.green);
      case Permission.microphone:
        return Icon(Icons.mic, color: Colors.green);
      case Permission.phone:
        return Icon(Icons.phone, color: Colors.green);
      case Permission.sms:
        return Icon(Icons.sms, color: Colors.green);
      case Permission.notification:
        return Icon(Icons.notifications, color: Colors.green);
      default:
        return Icon(Icons.settings, color: Colors.green);
    }
  }

  Widget _buildPermissionTile(Permission permission) {
    final status = _permissionStatuses[permission];
    final isGranted = status?.isGranted ?? false;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _getPermissionIcon(permission),
        ),
        title: Text(
          _getPermissionTitle(permission),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          _getPermissionDescription(permission),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: Switch(
          value: isGranted,
          onChanged: (value) => _handlePermissionChange(permission, value),
          activeColor: Colors.green,
          activeTrackColor: Colors.green.withOpacity(0.3),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPermissions,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'App Permissions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Manage app permissions to ensure all features work correctly',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    ..._permissionStatuses.keys.map(_buildPermissionTile).toList(),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
} 