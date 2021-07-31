class UserModel
{
  String uid;
  String firstName;
  String lastName;
  String phone;

  UserModel({this.firstName, this.lastName, this.phone});
 UserModel.fromJson(Map<String,dynamic>json)
 {
  // uid=json["uid"];  Because we always set key fromfirebase to uid so here we can dono,t bind it
   firstName=json["firstName"];
   lastName=json["lastName"];
   phone=json["phone"];
 }
 Map<String,dynamic>tojson()
  {
    final Map<String,dynamic> data=new Map<String,dynamic>();
    data["firstName"]=this.firstName;
    data["lastName"]=this.lastName;
    data["phone"]=this.phone;
    //data["uid"]=this.uid;
    return data;
}
}