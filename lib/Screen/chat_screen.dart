import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/Model/chat_info.dart';
import 'package:flutter_chat_app/Model/chat_message.dart';
import 'package:flutter_chat_app/Model/userModel.dart';
import 'package:flutter_chat_app/const/const.dart';
import 'package:flutter_chat_app/state/state_manager.dart';
import 'package:flutter_chat_app/utils/utils.dart';
import 'package:flutter_chat_app/widgets/bubble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class DetailScreen extends ConsumerWidget
{
  DetailScreen({this.app, this.user});
  FirebaseApp app;
  User user;

  DatabaseReference offsetRef,chatRef;
  FirebaseDatabase database;

  TextEditingController _textEditingController=TextEditingController();
  ScrollController _scrollController=ScrollController();

  @override
  Widget build(BuildContext context, watch) {
  var friendUser=watch(chatUser).state;
  return Scaffold(
    appBar: AppBar(
      centerTitle: true,
      title: Text("${friendUser.firstName} ${friendUser.lastName}"),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              flex: 8,
                child: friendUser.uid!=null?
            FirebaseAnimatedList(
              controller: _scrollController,
                sort: (DataSnapshot a,DataSnapshot b)=>b.key.compareTo(a.key),
                reverse: true,
                query: loadchatContent(context,app),
                itemBuilder:(BuildContext context,DataSnapshot snapshot,
                    Animation<double> animation,int index)
                {
                  var chatContent=ChatMessage.fromJson(
                    json.decode(json.encode(snapshot.value)));
                  return SizeTransition(sizeFactor:animation,
                  child: chatContent.picture ? chatContent.senderId==user.uid ?
                    bubbleImageFromUser(chatContent):bubbleImageFromFriend(chatContent):
                      chatContent.senderId==user.uid?
                          bubbleTextFromUser(chatContent):bubbleTextFromFriend(chatContent),);
                }):
            Center(child:CircularProgressIndicator())),
           Expanded(
             flex: 1,
               child: Row(
             children: [
               Expanded(child:
               TextField(
                 keyboardType: TextInputType.multiline,
                 expands: true,
                 minLines: null,
                 maxLines: null,
                 decoration: InputDecoration(
                     hintText: "Enter your message"),
                 controller: _textEditingController,
               )),
               IconButton(icon: Icon(Icons.send),
                   onPressed:()
                   {
                     offsetRef.once()
                         .then((DataSnapshot snapshot)
                     {

                       print("SNAPSHOT VALUE ${snapshot.value}");
                       print("SNAPSHOT INT ${snapshot.value as int}");
                       var duration = DateTime.now().timeZoneOffset;
                       print("SNAPSHOT offset ${duration}");
                       var offset=snapshot.value as int;
                       var estimatedServerTimeInMs=
                           DateTime.now().microsecondsSinceEpoch + offset;
                       submitChat(context,estimatedServerTimeInMs);
                     });

                     //Auto scroll chat layout to end
                     autoScroll(_scrollController);
                   })
             ],
           ))
          ],),
      ),
    ),
  );
  }

  loadchatContent(BuildContext context, FirebaseApp app) {
    database=FirebaseDatabase(app: app);
    offsetRef=database.reference().child(".info/serverTimeOffset");
    chatRef=database.reference()
    .child(CHAT_REF)
    .child(getRoomId(user.uid,context.read(chatUser).state.uid))
    .child(DETAIL_REF);
    return chatRef;
  }

  void submitChat(BuildContext context, int estimatedServerTimeInMs) {
  ChatMessage chatMessage=ChatMessage();
  chatMessage.name=createName(context.read(userLogged).state);
  chatMessage.content=_textEditingController.text;
  chatMessage.timeStamp=estimatedServerTimeInMs;
  chatMessage.senderId=user.uid;

  //Image and text
    chatMessage.picture=false;
    submitChatToFirebase(context,chatMessage,estimatedServerTimeInMs);
  }

  void submitChatToFirebase(BuildContext context, ChatMessage chatMessage, int estimatedServerTimeInMs) {
    chatRef.once().then((DataSnapshot snapshot)
    {

      if(snapshot!=null) //if user already create chat before
        {
          appendChat(context,chatMessage,estimatedServerTimeInMs);
        }
      else
        createChat(context,chatMessage,estimatedServerTimeInMs);
    });
  }

  void createChat(BuildContext context, ChatMessage chatMessage, int estimatedServerTimeInMs) {
    //Create chat info
    ChatInfo chatInfo=new ChatInfo(
      createId: user.uid,
      friendName: createName(context.read(chatUser).state),
      friendId: context.read(chatUser).state.uid,
      createName: createName(context.read(userLogged).state),
      lastMessage: chatMessage.picture?"<>Image":chatMessage.content,
      lastUpdate: DateTime.now().microsecondsSinceEpoch,
      createDate: DateTime.now().microsecondsSinceEpoch,

    );
    //Add to firebase
    database.reference()
    .child(ChatLIST_REF)
    .child(user.uid)
    .child(context.read(chatUser).state.uid)
    .set(<String,dynamic>{
     // context.read(chatUser).state.uid:chatInfo
      "lastUpdate":chatInfo.lastUpdate,
      "lastMessage":chatInfo.lastMessage,
      "createId":chatInfo.createId,
      "friendId":chatInfo.friendId,
      "createName":chatInfo.createName,
      "friendName":chatInfo.friendName,
      "creatDate":chatInfo.createDate,



    }).then((value)
    {
      //after success copy to friend chat list
      database.reference()
          .child(ChatLIST_REF)
          .child(context.read(chatUser).state.uid)
      .child(user.uid)
           .set
      //     (<String,dynamic>{
      //   // context.read(chatUser).state.uid:chatInfo
      //   "lastUpdate":chatInfo.lastUpdate,
      //   "lastMessage":chatInfo.lastMessage,
      //   "createId":chatInfo.createId,
      //   "friendId":chatInfo.friendId,
      //   "createName":chatInfo.createName,
      //   "friendName":chatInfo.friendName,
      //   "creatDate":chatInfo.createDate,
      //
      //
      //
      // })
        (<String,ChatInfo>
      {
        user.uid:chatInfo
      })
          .then((value)
      {
        //After success add on chatt Refrence
        chatRef.push().set(<String,dynamic>
        {
          "uid":chatMessage.uid,
          "name":chatMessage.name,
          "content":chatMessage.content,
          "pictureLink":chatMessage.pictureLink,
          "picture":chatMessage.picture,
          "senderId":chatMessage.senderId,
          "timeStamp":chatMessage.timeStamp,
        }).then((value) 
        {
          //clear text content
          _textEditingController.text="";
          //Auto scroll
          //auto scroll
          autoScrollReverse(_scrollController);
        }).catchError((e)
        {
          showOnlySnackBar(context, "Error submit Chat REF");
        });
      });
    }).catchError((e)
    {
      showOnlySnackBar(context, "Error Can not submit chat list");

    });

  }

  void appendChat(BuildContext context, ChatMessage chatMessage, int estimatedServerTimeInMs) {
    var update_data=Map<String,dynamic>();
    update_data["lastMessage"]=estimatedServerTimeInMs;
    if(chatMessage.picture)
      update_data["lastMessage"]="<Image>";
    else
      update_data["lastMessage"]=chatMessage.content;

    //Update
    database.reference()
    .child(ChatLIST_REF)
    .child(user.uid)//You
    .child(context.read(chatUser).state.uid)//Friend
    .update(update_data)
    .then((value)
    {
      //copy to friend
      database.reference().child(ChatLIST_REF)
          .child(context.read(chatUser).state.uid)//friend
          .child(user.uid)//you
      .update(update_data)
          .then((value)
      {
        //Add to chat ref
        chatRef.push().set(<String,dynamic>
        {
          "uid":chatMessage.uid,
          "name":chatMessage.name,
          "content":chatMessage.content,
          "pictureLink":chatMessage.pictureLink,
          "picture":chatMessage.picture,
          "senderId":chatMessage.senderId,
          "timeStamp":chatMessage.timeStamp,
        }).then((value)
        {
          //clear text content
          _textEditingController.text="";
          //Auto scroll
          //auto scroll
          autoScrollReverse(_scrollController);
        }).catchError((e)
        {
          showOnlySnackBar(context, "Error submit Chat REF");
        });

      }).catchError((e)
      {
        showOnlySnackBar(context, "Can not update friend chat list");
      });
    })
    .catchError((e)=>showOnlySnackBar(context, "Cannot update user Chat List"));
  }





}