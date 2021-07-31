import 'package:flutter_chat_app/Model/userModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatUser=StateProvider((ref)=>UserModel());
final userLogged=StateProvider((ref)=>UserModel());