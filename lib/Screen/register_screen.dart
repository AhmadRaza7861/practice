import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/Model/userModel.dart';
import 'package:flutter_chat_app/const/const.dart';
import 'package:flutter_chat_app/utils/utils.dart';
class RegisterScreen extends StatelessWidget {
  FirebaseApp app;
User user;

  RegisterScreen({this.app,this.user});
  TextEditingController  _firstNameControler=new TextEditingController();
  TextEditingController  _lastNameControler=new TextEditingController();
  TextEditingController  _phoneController=new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Register"),
        ),
        body:Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _firstNameControler,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(hintText: "First Name"),
                    ),
                  ),
                  SizedBox(width: 16,),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _lastNameControler,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(hintText: "Last Name"),
                    ),
                  ),
                ],
              ),
              TextField(
                readOnly: true,
                controller: _phoneController,
                decoration: InputDecoration(hintText: user.phoneNumber ?? "Null"),
              ),
              ElevatedButton(
                onPressed:(){
                  if(_firstNameControler.text.isEmpty||_firstNameControler==null)
                    {
                      showOnlySnackBar(context, "Please Enter First Name");
                    }
                  else if(_lastNameControler.text.isEmpty||_lastNameControler==null)
                  {
                    showOnlySnackBar(context, "Please Enter Last Name");
                  }
                  else
                    {
                      UserModel userModel=new UserModel(firstName: _firstNameControler.text,
                      lastName: _lastNameControler.text,
                      phone: user.phoneNumber);

                      //Submit o firebase
                      FirebaseDatabase(app: app).reference().child(PEOPLE_REF).child(user.uid)
                      .set(<String,dynamic>
                      {
                        "firstName":userModel.firstName,
                        "lastName":userModel.lastName,
                        "phone":userModel.phone
                      })
                      .then((value) {
                        showOnlySnackBar(context,"Register Success");
                        Navigator.pop(context);
                      }).catchError((e)
                      {
                        showOnlySnackBar(context, "$e");
                      });
                    }
              },
                child: Text("Register",style: TextStyle(color: Colors.black),),
              )
            ]
          ),
        )
    );
  }
}
