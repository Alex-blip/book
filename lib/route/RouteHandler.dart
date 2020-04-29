import 'dart:convert' as convert;

import 'package:book/entity/BookInfo.dart';
import 'package:book/entity/GBook.dart';
import 'package:book/main.dart';
import 'package:book/view/AllTagBook.dart';
import 'package:book/view/BookDetail.dart';
import 'package:book/view/Forgetpass.dart';
import 'package:book/view/PersonCenter.dart';
import 'package:book/view/ReadBook.dart';
import 'package:book/view/Register.dart';
import 'package:book/view/Search.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

// 根目录
var rootHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  return MainPage();
});

// 设置页 - 示例：不传参数
var searchHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  return Search();
});
var loginHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  return Login();
});
var registerHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  return Register();
});
var modifyPasswordHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  return ForgetPass();
});
var allTagBookHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  String title = (params['title'][0]);
  List list = convert.jsonDecode(params["bks"][0]);
  List<GBook> list2 = list.map((f) => GBook.fromJson(f)).toList();
  return AllTagBook(title, list2);
});

//// 网页加载 - 示例：传多个字符串参数
//var webViewHandler =
//    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
//  // params内容为  {title: [我是标题哈哈哈], url: [https://www.baidu.com/]}
//  String title = params['title']?.first;
//  String url = params['url']?.first;
//  return WebViewUrlPage(
//    title: title,
//    url: url,
//  );
//});

// 示例：传多个model参数
var readHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
//  print('params: $params');
//  String model = params['userInfoModel']?.first;
//  print('model: $model');
//  // model: {name: yuanzhiying, age: 30, height: 1.78, weight: 74.0}
//  Map<String, dynamic> jsonMap = convert.jsonDecode(model);
//  print('jsonMap: $jsonMap');
//  UserInfoModel _model = UserInfoModel.fromJson(jsonMap);

  BookInfo _bookInfo = BookInfo.fromJson(convert.jsonDecode(params['read'][0]));

  return ReadBook(_bookInfo);
});
var detailHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  BookInfo _bookInfo =
      BookInfo.fromJson(convert.jsonDecode(params['detail'][0]));

  return BookDetail(_bookInfo);
});