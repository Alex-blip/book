import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:book/common/LoadDialog.dart';
import 'package:book/common/ReaderPageAgent.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/common/toast.dart';
import 'package:book/common/util.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/entity/BookTag.dart';
import 'package:book/entity/Chapter.dart';
import 'package:book/entity/ReadPage.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ReadModel with ChangeNotifier {
  BookInfo bookInfo;
  List<Chapter> chapters = [];

  //本书记录
  BookTag bookTag;
  ReadPage prePage;
  ReadPage curPage;
  ReadPage nextPage;
  List<Widget> allContent = [];

  //页面控制器
  PageController pageController;

  //章节slider value
  double value;

  //背景色数据
  List<List> bgs = [
    [250, 245, 235],
    [245, 234, 204],
    [230, 242, 230],
    [228, 241, 245],
    [245, 228, 228],
  ];
  List<String> bgimg = [
    "https://qidian.gtimg.com/qd/images/read.qidian.com/body_base_bg.5988a.png",
    "https://qidian.gtimg.com/qd/images/read.qidian.com/theme/body_theme1_bg.9987a.png",
    "https://qidian.gtimg.com/qd/images/read.qidian.com/theme/body_theme2_bg.75a33.png",
    "https://qidian.gtimg.com/qd/images/read.qidian.com/theme/theme_3_bg.31237.png",
    "https://qidian.gtimg.com/qd/images/read.qidian.com/theme/body_theme5_bg.85f0d.png",
  ];

  //页面字体大小
  double fontSize = 32.0;

  //显示上层 设置
  bool showMenu = false;

  //章节切换过程中 页面切换数
  int offset = 0;

  //offset tag 上一章 -1 下一张 +1
  int offsetTag = 0;

  //背景色索引
  int bgIdx = 0;

//章节翻页标志
  bool changeCpOk = true;

  //页面宽高
  double contentH;
  double contentW;

  //页面上下文
  BuildContext context;

//是否修改font
  bool font = false;

  //获取本书记录
  getBookRecord() async {
    showMenu = false;
    font = false;
    offset = 0;
    offsetTag = 0;
    if (SpUtil.haveKey(bookInfo.Id)) {
      bookTag =
          BookTag.fromJson(await parseJson(SpUtil.getString(bookInfo.Id)));
      List list = await parseJson((SpUtil.getString('${bookInfo.Id}chapters')));
      chapters = list.map((e) => Chapter.fromJson(e)).toList();
      getChapters();
      //书的最后一章
      if (bookInfo.CId == "-1") {
        bookTag.cur = chapters.length - 1;
      }
      intiPageContent(bookTag.cur, false);
      pageController = PageController(initialPage: bookTag.index);
      value = bookTag.cur.toDouble();
      notifyListeners();
      //本书已读过
    } else {
      bookTag = BookTag(0, 0, bookInfo.Name);
      if (SpUtil.haveKey('${bookInfo.Id}chapters')) {
        var string = SpUtil.getString('${bookInfo.Id}chapters');
        List v = await parseJson(string);
        chapters = v.map((f) => Chapter.fromJson(f)).toList();
      }
      pageController = PageController(initialPage: 0);
      await getChapters();
      if (bookInfo.CId == "-1") {
        bookTag.cur = chapters.length - 1;
      }
      intiPageContent(bookTag.cur, false);
    }
  }

  Future intiPageContent(int idx, bool jump) async {
    showGeneralDialog(
      context: context,
      barrierLabel: "",
      barrierDismissible: true,
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (BuildContext context, Animation animation,
          Animation secondaryAnimation) {
        return LoadingDialog();
      },
    );
    prePage = await loadChapter(idx - 1);
    curPage = await loadChapter(idx);
    nextPage = await loadChapter(idx + 1);
    Navigator.pop(context);

    fillAllContent();
    value = bookTag.cur.toDouble();
    if (jump) {
      int ix = prePage?.pageOffsets?.length ?? 0;
      pageController.jumpToPage(ix);
    }
  }

  changeChapter(int idx) async {
    bookTag.index = idx;
    offset = offset + offsetTag;
    print("calc offset $offset $offsetTag");

    int preLen = prePage?.pageOffsets?.length ?? 0;
    int curLen = curPage?.pageOffsets?.length ?? 0;
    if (changeCpOk) {
      if ((idx + 1 - preLen) > (curLen)) {
        changeCpOk = false;
        int temp = bookTag.cur + 1;
        if (temp >= chapters.length) {
          Toast.show("已经是最后一页");
          pageController.previousPage(
              duration: Duration(microseconds: 1), curve: Curves.ease);
        } else {
          offset = 1;
          offsetTag = 1;

          bookTag.cur += 1;
          prePage = curPage;
          if (nextPage.chapterName == "-1") {
            showGeneralDialog(
              context: context,
              barrierLabel: "",
              barrierDismissible: true,
              transitionDuration: Duration(milliseconds: 300),
              pageBuilder: (BuildContext context, Animation animation,
                  Animation secondaryAnimation) {
                return LoadingDialog();
              },
            );
            curPage = await loadChapter(bookTag.cur);
            int preLen = prePage?.pageOffsets?.length ?? 0;
            int curLen = curPage?.pageOffsets?.length ?? 0;
            bookTag.index = preLen + curLen - 1;
            Navigator.pop(context);
          } else {
            curPage = nextPage;
          }
          nextPage = await loadChapter(bookTag.cur + 1);
          fillAllContent();
          print("my offset $offset");
          int realIdx = (prePage?.pageOffsets?.length ?? 0) + offset;
          print(realIdx);
          pageController.jumpToPage(realIdx - 1);
          offset = 0;
          offsetTag = 0;
        }
        changeCpOk = true;
      } else if (idx < preLen) {
        changeCpOk = false;
        int temp = bookTag.cur - 1;
        if (temp < 0) {
          return;
        } else {
          offsetTag = -1;
          offset = -1;
          bookTag.cur -= 1;
          nextPage = curPage;
          curPage = prePage;
          prePage = await loadChapter(bookTag.cur - 1);

          fillAllContent();
          int ix = (prePage?.pageOffsets?.length ?? 0) +
              curPage.pageOffsets.length +
              offset;
          pageController.jumpToPage(ix);
          offset = 0;
          offsetTag = 0;
//        notifyListeners();
        }
        changeCpOk = true;
      }
    }
  }

  switchBgColor(i) {
    bgIdx = i;
    SpUtil.putInt('bgIdx', i);

    notifyListeners();
  }

  Future getChapters() async {
    var url = Common.chaptersUrl + '/${bookInfo.Id}/${chapters?.length ?? 0}';
    Response response =
        await Util(chapters.isEmpty ? context : null).http().get(url);

    List data = response.data['data'];
    if (data == null) {
      print("load cps ok");
      return;
    }

    List<Chapter> list = data.map((c) => Chapter.fromJson(c)).toList();
    chapters.addAll(list);
    //书的最后一章
    if (bookInfo.CId == "-1") {
      bookTag.cur = chapters.length - 1;
      value = bookTag.cur.toDouble();
    }
    SpUtil.putString('${bookInfo.Id}chapters', jsonEncode(chapters));
    notifyListeners();
    print("load cps ok");
  }

  Future<ReadPage> loadChapter(int idx) async {
    ReadPage r = new ReadPage();
    if (idx < 0) {
      r.chapterName = "1";
      r.pageOffsets = List(1);
      r.chapterContent = "封面";
      return r;
    } else if (idx == chapters.length) {
      r.chapterName = "-1";
      r.pageOffsets = List(1);
      r.chapterContent = "没有更多内容,等待作者更新";
      return r;
    }

    r.chapterName = chapters[idx].name;
    String id = chapters[idx].id;

    if (!SpUtil.haveKey(id)) {
      r.chapterContent = await compute(requestDataWithCompute, id);

      SpUtil.putString(id, r.chapterContent);

      r.pageOffsets = new ReaderPageAgent()
          .getPageOffsets(r.chapterContent, contentH, contentW, fontSize);
      SpUtil.putString('pages' + id, r.pageOffsets.join('-'));
      chapters[idx].hasContent = 2;
    } else {
      r.chapterContent = SpUtil.getString(id);
      if (SpUtil.haveKey('pages' + id)) {
        r.pageOffsets = SpUtil.getString('pages' + id)
            .split('-')
            .map((f) => int.parse(f))
            .toList();
      } else {
        r.pageOffsets = new ReaderPageAgent()
            .getPageOffsets(r.chapterContent, contentH, contentW, fontSize);
      }
    }
    return r;
  }

  fillAllContent() {
    allContent = [];
    if (prePage != null) {
      allContent.addAll(chapterContent(prePage));
    }
    if (curPage != null) {
      allContent.addAll(chapterContent(curPage));
    }
    if (nextPage != null) {
      allContent.addAll(chapterContent(nextPage));
    }
    notifyListeners();
  }

//  Color.fromRGBO(122, 122, 122, 1)
  Widget readView() {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel model, child) {
      return Container(
        decoration: model.dark ? null :BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider(
                 bgimg[bgIdx]),
            fit: BoxFit.cover,
          ),
        ),
        color: model.dark ? Colors.black : null,
        child: PageView.builder(
          controller: pageController,
          physics: AlwaysScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return allContent[index];
          },
          //条目个数
          itemCount: (prePage?.pageOffsets?.length ?? 0) +
              (curPage?.pageOffsets?.length ?? 0) +
              (nextPage?.pageOffsets?.length ?? 0),
          onPageChanged: (idx) => changeChapter(idx),
        ),
      );
    });
  }

  modifyFont() {
    if (!font) {
      font = !font;
    }

    SpUtil.putDouble('fontSize', fontSize);
    bookTag.index = 0;

    var keys = SpUtil.getKeys();
    for (var key in keys) {
      if (key.startsWith("pages")) {
        SpUtil.remove(key);
      }
    }
    intiPageContent(bookTag.cur, true);
//    notifyListeners();
  }

  toggleShowMenu() {
    showMenu = !showMenu;
    notifyListeners();
  }

  saveData() {
    SpUtil.putString(bookInfo.Id, jsonEncode(bookTag));
  }

  void tapPage(BuildContext context, TapDownDetails details) {
    var wid = ScreenUtil.getScreenW(context);
    var space = wid / 3;
    var curWid = details.localPosition.dx;
    if (curWid > 0 && curWid < space) {
      pageController.previousPage(
          duration: Duration(microseconds: 1), curve: Curves.ease);
    } else if (curWid > space && curWid < 2 * space) {
      toggleShowMenu();
    } else {
      pageController.nextPage(
          duration: Duration(microseconds: 1), curve: Curves.ease);
    }
  }

  reCalcPages() {
    SpUtil.getKeys().forEach((f) {
      if (f.startsWith('pages')) {
        SpUtil.remove(f);
      }
    });
  }

  downloadAll() async {
    if (chapters?.isEmpty ?? 0 == 0) {
      await getChapters();
//      saveData();

    }
    List<String> ids = [];
    if (SpUtil.haveKey(Common.downloadlist)) {
      ids = SpUtil.getStringList(Common.downloadlist);
    }
    if (!ids.contains(bookInfo.Id)) {
      ids.add(bookInfo.Id);
    }
    SpUtil.putStringList(Common.downloadlist, ids);
    for (var chapter in chapters) {
      String id = chapter.id;
      if (!SpUtil.haveKey(id)) {
        String content = await compute(requestDataWithCompute, id);
        SpUtil.putString(chapter.id, content);
        chapter.hasContent = 2;
      }
    }
    Toast.show("${bookInfo?.Name ?? ""}下载完成");
    SpUtil.putString('${bookInfo.Id}chapters', jsonEncode(chapters));
  }

  static Future<String> requestDataWithCompute(String id) async {
    try {
      var url = Common.bookContentUrl + '/$id';
      var client = new HttpClient();
      var request = await client.getUrl(Uri.parse(url));
      var response = await request.close();
      var responseBody = await response.transform(utf8.decoder).join();
      var dataList = await parseJson(responseBody);
      var splist = ["…", "*", "-", "~"];
      String string = dataList['data']['content'];
      return string;
//      if (string.startsWith("\r\n")){
//        string=string.substring(2);
//      }
//      return string.replaceAll(" ", "\t\t");
    } catch (e) {
      print(e);
    }
  }

  List<Widget> chapterContent(ReadPage r) {
    List<Widget> contents = [];
    for (var i = 0; i < r.pageOffsets.length; i++) {
      var content = r.stringAtPageIndex(i);
      if (content.startsWith("\n")) {
        content = content.substring(1);
      }

      contents.add(
        Store.connect<ColorModel>(builder: (context, ColorModel model, child) {
          return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (TapDownDetails details) {
                tapPage(context, details);
              },
              child: (r.chapterName == "-1" || r.chapterName == "1")
                  ? Container(
                      child: Text(r.chapterContent),
                      alignment: Alignment.center,
                    )
                  : Container(
                      child: Column(
                        children: <Widget>[
                          SizedBox(height: ScreenUtil.getStatusBarH(context)),
                          Container(
                            height: 30,
                            padding: EdgeInsets.only(left: 3),
                            child: Text(
                              r.chapterName,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: model.font,
                                  color: model.dark
                                      ? Color.fromRGBO(142, 142, 142, 1)
                                      : null),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Container(
                                padding: EdgeInsets.only(
                                  right: 5,
                                  left: 15,
                                ),
                                child: Text.rich(
                                  TextSpan(children: [
                                    TextSpan(
                                        text: content,
                                        style: TextStyle(
                                            color: model.dark
                                                ? Color.fromRGBO(
                                                    122, 122, 122, 1)
                                                : null,
                                            fontSize: fontSize /
                                                Screen.textScaleFactor))
                                  ]),
                                  textAlign: TextAlign.justify,
                                  style: TextStyle(fontFamily: model.font),
                                )),
                          ),
                          Container(
                            height: 30,
                            padding: EdgeInsets.only(right: 8),
                            child: Row(
                              children: <Widget>[
                                Expanded(child: Container()),
                                Text(
                                  '第${i + 1}/${r.pageOffsets.length}页',
                                  style: TextStyle(
                                      color: model.dark
                                          ? Color.fromRGBO(122, 122, 122, 1)
                                          : null,
                                      fontSize: 13,
                                      fontFamily: model.font),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
                      width: double.infinity,
                      height: double.infinity,
                    ));
        }),
      );
    }
    return contents;
  }

  clear() {
    bookTag = null;
    allContent = null;
    chapters = [];
  }
}
