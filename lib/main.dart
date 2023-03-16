import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> backgroundHalder(RemoteMessage message) async {
  print("This is message");
  print(message.notification!.title);
  print(message.notification!.body);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(backgroundHalder);

  await Hive.initFlutter();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KTHP Bà Thông',
      theme: ThemeData.light(),
      home: const SignUpScreen(),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

Future<void> _launchInBrowser(String url) async {
  if (await canLaunch(url)) {
    await launch(
      url,
      forceSafariVC: false,
      forceWebView: false,
      headers: <String, String>{'header_key': 'header_value'},
    );
  } else {
    throw 'Could not launch $url';
  }
}

Future<void> _launchInApp(String url) async {
  if (await canLaunch(url)) {
    await launch(
      url,
      forceSafariVC: false,
      forceWebView: true,
      enableJavaScript: true,
      headers: <String, String>{'header_key': 'header_value'},
    );
  } else {
    throw 'Could not launch $url';
  }
}

Future<void> _showMyDialogValid(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Đăng nhập'),
        content: SingleChildScrollView(
          child: ListBody(
            children: const <Widget>[
              Text("Thông tin đăng nhập chưa đúng, vui lòng đăng nhập lại."),
              // Text('Would you like to approve of this message?'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

class _SignUpScreenState extends State<SignUpScreen> {

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  // bool _validate = false;

  String notificationMsg = "Chờ tin nhắn";

  bool isChecked = false;
  late Box box1;

  void initState()
  {
    super.initState();
    FirebaseMessaging.instance.getInitialMessage().then((event){
      if (event != null) {
        setState(() {
          notificationMsg =
          "${event.notification!.title} ${event.notification!.body}";
        });
      }
    });

    FirebaseMessaging.onMessage.listen((event) {
      setState((){
        notificationMsg = "${event.notification!.title} ${event.notification!.body}";
      });

    });

    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      setState((){
        notificationMsg = "${event.notification!.title} ${event.notification!.body}";
      });

    });

    createOpenBox();

  }

  void createOpenBox()async{
    box1 = await Hive.openBox('logindata');
    //getdata();  // when user re-visit app, we will get data saved in local database
    //how to get data from hive db check it in below steps
    getdata();
  }

  void getdata()async{
    isChecked = false;
    setState(() {
    });

    if(box1.get('username') != null && box1.get('username') != '' ){
      usernameController.text = box1.get('username');
      isChecked = true;
      setState(() {
      });
    }

    if(box1.get('password') != null && box1.get('password') != '' ){
      passwordController.text = box1.get('password');
      isChecked = true;
      setState(() {
      });
    }

  }



  void login(String username , password) async {

    try{

      Response response = await post(
          Uri.parse('https://www.unicard123.com/hethong/apipost.php'),
          body: {
            'rquest' : 'loginuser',
            'userna' : username,
            'passwr' : password
          }
      );
      final String statusCodeString = response.statusCode.toString();
      print("$statusCodeString");
      var data = jsonDecode(response.body.toString());
      print("$data");
      print(data['message']);
      String token = data['message'];

      if(response.statusCode == 203){
        print('Login successfully');
        if(isChecked){
          box1.put('username', username.toString());
          box1.put('password', password.toString());
        }
        else{
          box1.put('username', null);
          box1.put('password', null);
          isChecked = false;
        }

        _launchInApp('https://www.unicard123.com/hethong/admin/loginapi.php?token=$token');
      //
      }else {
        print('failed');
        box1.put('username', '');
        box1.put('password', '');
        isChecked = false;
        _showMyDialogValid(context);
      }
    }catch(e){
      print(e.toString());
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // set it to false
      // appBar: AppBar(
      //   // title: const Text('Đăng nhập MRIK'),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget> [
            Image.asset('images/sbeauty.png',
                height: 200,
                scale: 2.5,
                // color: Color.fromARGB(255, 15, 147, 59),
                ), //I

            // CircleAvatar(
            //   backgroundImage: AssetImage("images/profile.jpg"),
            // ),
            TextFormField(
              controller: usernameController,
              decoration: InputDecoration(
                  labelText: 'Tên đăng nhập',
                  icon: const Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: const Icon(Icons.people),
                  ),
                  // errorText: _validate == true ? 'Value Can\'t Be Empty' : null,
              ),
            ),
            SizedBox(height: 20,),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                  icon: const Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: const Icon(Icons.lock),
                  ),
                  // errorText: _validate ? 'Value Can\'t Be Empty' : null,
              ),

            ),
            SizedBox(height: 40,),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Checkbox(
                  value: isChecked,
                  onChanged: (value){
                    isChecked = !isChecked;
                    setState(() {
                    });
                  },
                ),
                Text("Remember Me",style: TextStyle(color: Colors.black),),
              ],
            ),
            FlatButton(
              onPressed: (){
                if (usernameController.text.length < 3){
                  showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('Thông báo'),
                        content: Text('Vui lòng nhập đúng tên đăng nhập'),
                      )
                  );
                }
                else if (passwordController.text.length < 3)
                {
                  showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('Thông báo'),
                        content: Text('Vui lòng nhập mật khẩu'),
                      )
                  );
                }
                else
                {
                  login(usernameController.text.toString(), passwordController.text.toString());
                }

                //
              },
              child: Container(
                height: 60,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.circular(10)
                ),
                child: Center(
                  child: Text(
                    'Đăng nhập',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                    ),),),
              ),
            )
          ],
        ),
      ),
    );
  }
}