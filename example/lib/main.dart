import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login_facebook/flutter_login_facebook.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final plugin = FacebookLogin(debug: true);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHome(plugin: plugin),
    );
  }
}

class MyHome extends StatefulWidget {
  final FacebookLogin plugin;

  const MyHome({Key key, @required this.plugin})
      : assert(plugin != null),
        super(key: key);

  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  String _sdkVersion;
  FacebookAccessToken _token;
  FacebookUserProfile _profile;
  String _email;
  String _imageUrl;

  @override
  void initState() {
    super.initState();

    _getSdkVersion();
    _updateLoginInfo();
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _token != null && _profile != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login via Facebook example'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 8.0),
        child: Center(
          child: Column(
            children: <Widget>[
              if (_sdkVersion != null) Text("SDK v$_sdkVersion"),
              if (isLogin)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildUserInfo(context, _profile, _token, _email),
                ),
              isLogin
                  ? OutlineButton(
                      child: Text('Log Out'),
                      onPressed: _onPressedLogOutButton,
                    )
                  : OutlineButton(
                      child: Text('Log In'),
                      onPressed: _onPressedLogInButton,
                    ),
              if (!isLogin && Platform.isAndroid)
                OutlineButton(
                  child: Text('Express Log In'),
                  onPressed: () => _onPressedExpressLogInButton(context),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, FacebookUserProfile profile,
      FacebookAccessToken accessToken, String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_imageUrl != null)
          Center(
            child: Image.network(_imageUrl),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text('User: '),
            Text(
              '${profile.firstName} ${profile.lastName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Text('AccessToken: '),
        Container(
          child: Text(
            accessToken.token,
            softWrap: true,
          ),
        ),
        if (email != null) Text('Email: $email'),
      ],
    );
  }

  void _onPressedLogInButton() async {
    await widget.plugin.logIn(permissions: [
      FacebookPermission.publicProfile,
      FacebookPermission.email,
    ]);
    _updateLoginInfo();
  }

  void _onPressedExpressLogInButton(BuildContext context) async {
    final res = await widget.plugin.expressLogin();
    if (res.status == FacebookLoginStatus.Success) {
      _updateLoginInfo();
    } else {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text("Can't make express log in. Try regular log in."),
        ),
      );
    }
  }

  void _onPressedLogOutButton() async {
    await widget.plugin.logOut();
    _updateLoginInfo();
  }

  void _getSdkVersion() async {
    final sdkVesion = await widget.plugin.sdkVersion;
    setState(() {
      _sdkVersion = sdkVesion;
    });
  }

  void _updateLoginInfo() async {
    final plugin = widget.plugin;
    final token = await plugin.accessToken;
    FacebookUserProfile profile;
    String email;
    String imageUrl;

    if (token != null) {
      profile = await plugin.getUserProfile();
      if (token.permissions?.contains(FacebookPermission.email.name) ?? false)
        email = await plugin.getUserEmail();
      imageUrl = await plugin.getProfileImageUrl(width: 100);
    }

    setState(() {
      _token = token;
      _profile = profile;
      _email = email;
      _imageUrl = imageUrl;
    });
  }
}
