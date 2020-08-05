import 'dart:convert';

import 'package:book/common/FunUtil.dart';
import 'package:book/common/LoadDialog.dart';
import 'package:book/common/PicWidget.dart';
import 'package:book/common/common.dart';
import 'package:book/common/util.dart';
import 'package:book/entity/GBook.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class VideoDetail extends StatefulWidget {
  final GBook gBook;

  VideoDetail(this.gBook);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return VideoDetailState();
  }
}

class VideoDetailState extends State<VideoDetail> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Store.connect<ColorModel>(
      builder: (context, ColorModel model, child) => Theme(
        child: Scaffold(
            appBar: AppBar(
              title: Text(this.widget.gBook.name),
              elevation: 0,
              centerTitle: true,
              actions: <Widget>[
                GestureDetector(
                  child: Center(
                    child: Text('美剧'),
                  ),
                  onTap: () {
                    Navigator.of(context).popUntil(ModalRoute.withName('/'));
                    eventBus.fire(new NavEvent(2));
                  },
                ),
                SizedBox(
                  width: 20,
                )
              ],
            ),
            body: FutureBuilder(
              future: getData(),
              builder:
                  (BuildContext context, AsyncSnapshot<Response> snapshot) {
                /*表示数据成功返回*/
                if (snapshot.hasData) {
                  List data = snapshot.data.data;

                  return SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(5.0),
                      child: Column(
                        children: <Widget>[
                          Container(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                PicWidget(
                                  this.widget.gBook.cover,
                                  width: 160,
                                  height: 200,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                  child: Container(
                                    child: Scrollbar(
                                      child: SingleChildScrollView(
                                        child: Text(data[0]),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            height: 200,
                          ),
                          SizedBox(
                            height: 5.0,
                          ),
                          Row(
                            children: <Widget>[
                              Padding(
                                child: Container(
                                  width: 4,
                                  height: 20,
                                  color: model.dark
                                      ? model.theme.textTheme.body1.color
                                      : model.theme.primaryColor,
                                ),
                                padding: EdgeInsets.only(left: 5.0, right: 3.0),
                              ),
                              Text(
                                "在线播放:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Container(),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 3, //主轴上子控件的间距
                            runSpacing: 5, //交叉轴上子控件之间的间
                            children: mItems(data[1]),
                          ),
                          Row(
                            children: <Widget>[
                              Padding(
                                child: Container(
                                  width: 4,
                                  height: 20,
                                  color: model.dark
                                      ? model.theme.textTheme.body1.color
                                      : model.theme.primaryColor,
                                ),
                                padding: EdgeInsets.only(left: 5.0, right: 3.0),
                              ),
                              Text(
                                "剧情简介:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Container(),
                              ),
                            ],
                          ),
                          Text(data[2]),
                          Row(
                            children: <Widget>[
                              Padding(
                                child: Container(
                                  width: 4,
                                  height: 20,
                                  color: model.dark
                                      ? model.theme.textTheme.body1.color
                                      : model.theme.primaryColor,
                                ),
                                padding: EdgeInsets.only(left: 5.0, right: 3.0),
                              ),
                              Text(
                                "影片截图:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Container(),
                              ),
                            ],
                          ),
                          showShutPic(data[3])
                        ],
                      ),
                    ),
                  );
                } else {
                  return LoadingDialog();
                }
              },
            )),
        data: model.theme,
      ),
    );
  }

  Future<Response> getData() async {
    String url = Common.m_detail + '/${this.widget.gBook.id}';
    Response future = await Util(null).http().get(url);
    return future;
  }

  List<Widget> mItems(List<dynamic> list) {
    List<Widget> wds = [];

    for (var value in list) {
      Map map = Map.castFrom(value);
      wds.add(FlatButton(
        child: Text(
          map.values.elementAt(0),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: () {
          var jsonEncode2 = jsonEncode(list);
          FunUtil.saveMoviesRecord(
              this.widget.gBook.cover,
              this.widget.gBook.name,
              map.keys.elementAt(0),
              map.values.elementAt(0),
              jsonEncode2);

          Routes.navigateTo(context, Routes.lookVideo, params: {
            "name": this.widget.gBook.name,
            "id": map.keys.elementAt(0),
            "mcids": jsonEncode2
          });
        },
        color: Store.value<ColorModel>(context).theme.primaryColor,
      ));
    }
    return wds;
  }

  Widget showShutPic(var pics) {
    List pcs = pics;
    if (pcs.isEmpty) {
      return Container();
    }
    List<Widget> wds = [];
    for (var value in pcs) {
      wds.add(PicWidget(
        value,
        width: (ScreenUtil.getScreenW(context) - 40) / 2,
        height: ((ScreenUtil.getScreenW(context) - 40) / 2) * 0.2,
      ));
    }
    return GridView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(5.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 1.0,
          crossAxisSpacing: 10.0,
          childAspectRatio: 1),
      children: wds,
    );
  }
}
