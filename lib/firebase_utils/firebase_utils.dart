import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart'as FirebaseAuth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/Model/chat_info.dart';
import 'package:flutter_chat_app/Model/userModel.dart';
import 'package:flutter_chat_app/const/const.dart';
import 'package:flutter_chat_app/state/state_manager.dart';
import 'package:flutter_chat_app/utils/time_ago.dart';
import 'package:flutter_chat_app/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


Widget loadChatList(FirebaseDatabase database, DatabaseReference chatListRef) {
  return StreamBuilder(
    stream: chatListRef.onValue,
    builder: (BuildContext context,AsyncSnapshot<Event> snapshot)
    {
      if(snapshot.hasData)
        {
          print("First snapshot has data");
          List<ChatInfo> chatInfos=new List<ChatInfo>();
          Map<dynamic,dynamic> values=snapshot.data.snapshot.value;

          if(values!=null)
            {
              values.forEach((key, value) {
                var chatInfo=ChatInfo.fromjson(json.decode(json.encode(value)));
                chatInfos.add(chatInfo);
              });
            }

          return ListView.builder(
            itemCount: chatInfos.length,
              itemBuilder: (context,index)
              {
                var displayName=FirebaseAuth.FirebaseAuth
                    .instance.currentUser.uid==chatInfos[index].createId?
                    chatInfos[index].friendName:chatInfos[index].createName;
                return Consumer(builder: (context,watch,_)
                {
                  return GestureDetector(onTap: () {
                    print("Gesture decture");
                    database.reference()
                        .child(PEOPLE_REF)
                        .child(FirebaseAuth.FirebaseAuth.instance.currentUser
                        .uid
                        == chatInfos[index].createId ? chatInfos[index]
                        .friendId :
                    chatInfos[index].createId)
                        .once().then((DataSnapshot snapshot) {
                      if (snapshot != null) {
                        print("Snapshot not null");
                        //load user
                        UserModel userModel = UserModel.fromJson(
                            json.decode(json.encode(snapshot.value)));
                        userModel.uid = snapshot.key;

                        context
                            .read(chatUser)
                            .state = userModel; //assign to chat Friend user

                        // Load current user
                        database.reference().child(PEOPLE_REF)
                            .child(
                            FirebaseAuth.FirebaseAuth.instance.currentUser.uid)
                            .once().then((value) {
                          UserModel currentUserModel = UserModel.fromJson(
                              json.decode(json.encode(value.value)));
                          currentUserModel.uid = value.key;
                          context
                              .read(userLogged)
                              .state = currentUserModel;
                          Navigator.pushNamed(context, "/detail");
                        })
                            .catchError((e) =>
                            showOnlySnackBar(
                                context, "Cannot load user information "));
                      }
                    });
                    },
                    child:Column(
                      children: [
                        Text("${TimeAgo.timeAgoSinceDate(chatInfos[index].lastUpdate)}"),
                        ListTile(
                          leading:CircleAvatar(
                            backgroundColor: Colors.primaries[
                              Random().nextInt(Colors.primaries.length)
                            ],
                            child: Text(
                              "${displayName.substring(0,1)}",
                              style: TextStyle(
                                color: Colors.white
                              ),
                            ),
                          ),
                          title: Text("$displayName"),
                          subtitle: Text("${chatInfos[index].lastMessage}"),
                          isThreeLine: true,
                        ),
                        Divider(thickness: 2,),

                      ],
                    ) ,

                    );
                });
              }
          );

        }
      else
        return Center(child: CircularProgressIndicator(),);
    },
  );
}


Widget loadPeople(FirebaseDatabase database,DatabaseReference _peopleRef) {
  return StreamBuilder(
    stream: _peopleRef.onValue,
    builder: (context,snapshot)
    {
      if(snapshot.hasData)
      {
        List<UserModel> userModels=new List<UserModel>.empty(growable: true);
        Map<dynamic,dynamic> values=snapshot.data.snapshot.value;
        values.forEach((key, value) {
          if(key!=FirebaseAuth.FirebaseAuth.instance.currentUser.uid)
          {
            var userModel=UserModel.fromJson(json.decode(json.encode(value)));
            userModel.uid=key;
            userModels.add(userModel);
          }
        });
        return ListView.builder(
            itemCount: userModels.length,
            itemBuilder:(context,index)
            {
              return GestureDetector(
                onTap: (){
                  // Load current user
                  database.reference().child(PEOPLE_REF)
                      .child(
                      FirebaseAuth.FirebaseAuth.instance.currentUser.uid)
                      .once().then((value) {
                    UserModel currentUserModel = UserModel.fromJson(
                        json.decode(json.encode(value.value)));
                    currentUserModel.uid = value.key;
                   // context.read(userLogged).state = currentUserModel;
                    context.read(chatUser).state=userModels[index];
                    Navigator.pushNamed(context, "/detail");

                   // Navigator.pushNamed(context, "/detail");
                  })
                      .catchError((e) =>
                      showOnlySnackBar(
                          context, "Cannot load user information info"));

                },
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.primaries
                      [
                      Random().nextInt(Colors.primaries.length)
                      ],
                        child: Text("${userModels[index].firstName.substring(0,1)}",
                          style: TextStyle(color: Colors.black54),),
                      ),
                      title: Text("${userModels[index].firstName}${userModels[index].lastName},",
                        style: TextStyle(color: Colors.black54),),
                      subtitle: Text("${userModels[index].phone}",
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                    Divider(thickness: 2,)
                  ],
                ),
              );
            });
      }
      else
        return Center(child: CircularProgressIndicator(),);
    },
  );
}