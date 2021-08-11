import 'dart:async';
import 'dart:convert';


import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/Model/chat_info.dart';
import 'package:flutter_chat_app/Model/chat_message.dart';
import 'package:flutter_chat_app/Model/userModel.dart';
import 'package:flutter_chat_app/const/const.dart';
import 'package:flutter_chat_app/state/state_manager.dart';
import 'package:flutter_chat_app/utils/utils.dart';
import 'package:flutter_chat_app/widgets/bubble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliding_sheet/sliding_sheet.dart';
import 'package:uuid/uuid.dart';

import 'camera_screen.dart';
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

  var isShowPicture=watch(isCapture).state;
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
             flex: isShowPicture ?2:1,
               child:Column
                 (
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisAlignment: MainAxisAlignment.start,
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   isShowPicture ? Container(width: 80,height: 80,
                   child:
                   Stack(
                     children: [
                       Image.file(File(context.read(thumbnailImage).state.path),
                           fit: BoxFit.fill),
                       Align(
                         alignment: Alignment.topRight,
                         child: IconButton(
                           icon: Icon(Icons.clear,color: Colors.black,),
                           onPressed: ()
                           {
                             context.read(isCapture).state=false;
                           },
                         ),
                       )
                     ],
                   ),):Container(),
                   Expanded(
                       child: Row(
                         children: [
                           IconButton(onPressed:()
                               {
                                 showBottomSheetPicture(context);
                               }, icon:Icon(Icons.add_a_photo) ),
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
  if(context.read(isCapture).state)
    chatMessage.picture=true;
    else
    chatMessage.picture=false;

    submitChatToFirebase(context,chatMessage,estimatedServerTimeInMs);
  }

  void submitChatToFirebase(BuildContext context, ChatMessage chatMessage, int estimatedServerTimeInMs) {
    chatRef.once().then((DataSnapshot snapshot)
    {
     // if(snapshot!=null) //if user already create chat before
      //   {
      //     appendChat(context,chatMessage,estimatedServerTimeInMs);
      //   }
      // else
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
          (<String,dynamic>{
        // context.read(chatUser).state.uid:chatInfo
        "lastUpdate":chatInfo.lastUpdate,
        "lastMessage":chatInfo.lastMessage,
        "createId":chatInfo.createId,
        "friendId":chatInfo.friendId,
        "createName":chatInfo.createName,
        "friendName":chatInfo.friendName,
        "creatDate":chatInfo.createDate,

      })




      //   (<String,ChatInfo>
      // {
      //   user.uid:chatInfo
      // })
          .then((value)async
      {
        if(chatMessage.picture)
          {
            //upload picture
            var pictureName=Uuid().v1();
            FirebaseStorage storage=FirebaseStorage.instanceFor(app: app);
            Reference ref=storage.ref()
            .child("images")
            .child("$pictureName.jpg");

            final metaData=SettableMetadata(
              contentType: "image/jpeg",
              customMetadata: {'picked-file-path':context.read(thumbnailImage).state.path}
            );
            var filePath=context.read(thumbnailImage).state.path;

            File file =new File(filePath);

            var task=await uploadFile(ref,metaData,file);
            task.whenComplete(()
            {
              //When upload done ,we will get download url to submit chat
              storage.ref().child("images/$pictureName.jpg")
                  .getDownloadURL().then((value)
              {
                //After success add on chatt Refrence
                chatMessage.pictureLink=value; //Add value to link

                writeChatToFirebase(context,chatRef,chatMessage);


              });
            });

          }
        else
          {
            //After success add on chatt Refrence
            writeChatToFirebase(context, chatRef, chatMessage);

          }

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

  showBottomSheetPicture(BuildContext context) async{
    final result=await showSlidingBottomSheet(context, builder:(context)
    {
      return SlidingSheetDialog(
        elevation: 8,
          cornerRadius: 16,
          snapSpec: const SnapSpec(
            snap: true,
              snappings: [0.4, 0.7, 1.0],
            //snappings: [0,2],
            positioning: SnapPositioning.relativeToAvailableSpace
          ),
          builder:(context,state)
      {
        return Container(
          height: 130,
          child: Padding(padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: ()async{
                await _navigateCamera(context);
              },
              child: Row(
                children: [
                  Icon(Icons.camera),
                  SizedBox(width: 10,),
                  Text("Camera",style: TextStyle(fontSize: 16,color: Colors.black),)
                ],
              ),
            ),
            SizedBox(height: 30,),
            GestureDetector(
              onTap: (){},
              child: Row(
                children: [
                  Icon(Icons.photo),
                  SizedBox(width: 20,),
                  Text("Photo",style: TextStyle(fontSize: 16,color: Colors.black),)
                ],
              ),
            ),
          ],
        ),
        ),);
      });
    });
  }

  _navigateCamera(BuildContext context) async{
    final result=await Navigator.push(context,
        MaterialPageRoute(builder: (context)=>MyCameraPage()));
    //set state
    context.read(thumbnailImage).state=result;
    context.read(isCapture).state=true;

    Navigator.pop(context);  //close sliding sheet
  }

 Future<UploadTask> uploadFile(Reference ref, SettableMetadata metaData, File file)async {
    var uploadTask=ref.putData(await file.readAsBytes(),metaData);
    return Future.value(uploadTask);
 }

  void writeChatToFirebase(BuildContext context,DatabaseReference chatRef, ChatMessage chatMessage) {
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
      context.read(isCapture).state=false;
      //Set picture hide
      if(chatMessage.picture)
        context.read(isCapture).state=false;
      //Auto scroll
      //auto scroll
      autoScrollReverse(_scrollController);
    }).catchError((e)
    {
      showOnlySnackBar(context, "Error submit Chat REF");
    });
  }
}