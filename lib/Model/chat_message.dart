import 'package:flutter_chat_app/main.dart';

class ChatMessage
{
  int timeStamp;
  String senderId;
  String name;
  String content;
  bool picture;
  String uid;
  String pictureLink;

  ChatMessage(
      {this.timeStamp,
      this.senderId,
      this.name,
      this.content,
      this.picture,
      this.uid,
      this.pictureLink});
  ChatMessage.fromJson(Map<String,dynamic> json)
  {
    timeStamp=json["timeStamp"];
    senderId=json["senderId"];
    name=json["name"];
    content=json["content"];
    picture=json["picture"];
    uid=json["uid"];
    pictureLink=json["pictureLink"];
  }

  Map<String,dynamic> tojson()
  {
    Map<String,dynamic>data=Map<String,dynamic>();
    data["timeStamp"]=timeStamp;
    data["name"]=name;
    data["senderId"]=senderId;
    data["content"]=content;
    data["picture"]=picture;
    data["pictureLink"]=pictureLink;
    data["uid"]=uid;
    return data;
  }
}