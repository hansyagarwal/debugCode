import 'package:flutter/material.dart';

class NUINavigator{

  static void popWithResult(BuildContext ctx, bool result){
    Navigator.pop(ctx,result);    
  }

  static void popAllAndPush(BuildContext ctx, Widget screen){
    Navigator.of(ctx).popUntil(ModalRoute.withName('str'));
    Navigator.push(ctx, MaterialPageRoute(builder: (ctx)=> screen));
  }

  static void push(BuildContext ctx, Widget screen) {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (ctx) => screen),
    );
  }

  static void popAndPush(BuildContext ctx, Widget screen){
    Navigator.pop(ctx);
    Navigator.push(ctx, MaterialPageRoute(builder: (ctx)=> screen));
  }

}