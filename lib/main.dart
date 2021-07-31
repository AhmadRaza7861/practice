import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth_ui/firebase_auth_ui.dart';
import 'package:firebase_auth_ui/providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/Model/userModel.dart';
import 'package:flutter_chat_app/Screen/chat_screen.dart';
import 'package:flutter_chat_app/Screen/register_screen.dart';
import 'package:flutter_chat_app/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'as FirebaseAuth;
import 'package:page_transition/page_transition.dart';

import 'const/const.dart';
import 'firebase_utils/firebase_utils.dart';
Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp app=await Firebase.initializeApp();
  runApp(ProviderScope(child: MyApp(app:app)));
}
class MyApp extends StatelessWidget {
  FirebaseApp app;
  MyApp({this.app}); // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      onGenerateRoute: (Setting)
      {
        switch(Setting.name)
        {
          case "/register":
            return PageTransition(child: RegisterScreen(app: app,user: FirebaseAuth.FirebaseAuth.instance.currentUser ?? null), type: PageTransitionType.fade,
            settings: Setting);
            break;
          case "/detail":
            return PageTransition(child: DetailScreen(app: app,user: FirebaseAuth.FirebaseAuth.instance.currentUser ?? null), type: PageTransitionType.fade,
                settings: Setting);
            break;
          default:return null;
        }
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page',app:app),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title,this.app}) : super(key: key);
  FirebaseApp app;



  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin{
  DatabaseReference _peopleRef,_chatListRef;
  FirebaseDatabase database;
  bool isUserInit=false;
  UserModel userLogged;
  final List<Tab> tabs=<Tab>
  [
    Tab(icon: Icon(Icons.chat),text: "chat",),
    Tab(icon: Icon(Icons.people),text: "Friend",)
  ];
TabController _tabController;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _tabController=TabController(length: tabs.length, vsync: this);
    database=FirebaseDatabase(app:widget.app);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      processLogin(context);

    });
  }
   @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: new TabBar(
          isScrollable: false,
          unselectedLabelColor: Colors.black45,
          labelColor: Colors.white,
          tabs: tabs,
          controller: _tabController,
        ),
      ),
      body://isUserInit ?Center(child:Text("${widget.app.name}"),) :Center(child: CircularProgressIndicator(),)
      isUserInit ?TabBarView(
        controller: _tabController,
          children: tabs.map((Tab tab) {
        if (tab.text == "chat")
         return loadChatList(database, _chatListRef);
        else
          return loadPeople(database,_peopleRef);
      }).toList())
          :Center(child: CircularProgressIndicator(),)
    );
  }

  void processLogin(BuildContext context) async{
    var user=FirebaseAuth.FirebaseAuth.instance.currentUser;
    if(user==null)  //if not login
      {
        FirebaseAuthUi.instance()
            .launchAuth([AuthProvider.phone(),])
            .then((fbUser)
        async{
         //refresh State
        await  _checkLoginState(context);
        }).catchError((e)
        {
          if(e is PlatformException)
            {
              if(e is PlatformException)
                {
                  if(e.code==FirebaseAuthUi.kUserCancelledError)
                    {
                      showOnlySnackBar(context,"User canceled logn");
                    }
                  else
                    {
                      showOnlySnackBar(context,"${e.message ?? 'Unk error'}");
                    }
                }
            }
        });
      }
    else //Already login
      {
       await _checkLoginState(context);
      }
  }

  Future<FirebaseAuth.User> _checkLoginState(BuildContext context) async{
    print("print Check Log IN State");
    //Already login get Token
    FirebaseAuth.FirebaseAuth.instance.currentUser
        .getIdToken()
        .then((Taken) async
    {
      print("print Check get tokennnnnnnnnnn");
      _peopleRef=database.reference().child(PEOPLE_REF);

      _chatListRef=database
      .reference()
      .child(ChatLIST_REF)
      .child(FirebaseAuth.FirebaseAuth.instance.currentUser.uid);

      //Load information
      print("Load information");
      _peopleRef.child(FirebaseAuth.FirebaseAuth.instance.currentUser.uid)
      .once()
      .then((snapshot)
      {
        print("Enter Load information");
        if(snapshot !=null && snapshot.value!=null)
          {
            print("Enter Snapshot!=null");
            setState(() {
              isUserInit=true;
            });
          }
        else
          {
            print("Enter Snapshot===null");
            setState(() {
              Navigator.pushNamed(context, "/register");
              isUserInit=true;
            });
          }
      });
    });
    return FirebaseAuth.FirebaseAuth.instance.currentUser;
  }
}
