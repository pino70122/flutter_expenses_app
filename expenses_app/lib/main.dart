import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';       // 日付
import 'package:flutter_localizations/flutter_localizations.dart'; //日本語化
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // データベース
import 'package:path/path.dart';
import 'dart:io' show Platform; // プラットフォームを確認
import 'package:window_size/window_size.dart'; // ウィンドウのサイズを制限

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


/////////////////////////////////////////////////////////////////////////////////////////////////// データベースの準備
// データベース操作用の変数
Database? database;

Future<void> initDB() async {
  // パスを準備
  String dbPath = await getDatabasesPath();
  String path = join(dbPath, "expenses_app.db") ;

  // データベースを開く or 作成する
  database = await openDatabase(
    path,
    version: 1,
    onCreate: (Database db, int version) async {
      // テーブルを作成
      await db.execute(
        "CREATE TABLE Expenses_App ("
          "id INTEGER PRIMARY KEY, date TEXT, amount INTEGER, category TEXT, memo TEXT)"
      );
    } 
  );
}

/////////////////////////////////////////////////////////////////////////////////////////////////// main関数
void main() async {
  //debugPaintSizeEnabled = true; // ウィジェットのエッジを見えるようにする
  // 初期化関連
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  // DBを開く
  await initDB();
  // ウィンドウのサイズを制限
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle("Expenses App"); // ウィンドウの名前
    setWindowMinSize(const Size(800, 600)); // 最小サイズ
  }
  // UIを展開
  runApp(const MyApp());
}
/////////////////////////////////////////////////////////////////////////////////////////////////// MyApp関数
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 日本語化
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('ja', 'JP'),  // Japanese, Japan
      ],
      home: const MainPage(),
      // レイアウト
      /*
      home: Scaffold(
        appBar: AppBar(title: Text("支出入力"),),
        body: Input(),
      )
      */
    );
  }
}
/////////////////////////////////////////////////////////////////////////////////////////////////// ページ遷移クラス
class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // ページ遷移用のコントローラー
  final PageController _pageController = PageController();
  
  // ページを戻す関数
  void pageBack() {
    _pageController.previousPage(
      duration: Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
  }

  // ページを進める関数
  void pageForward() {
    // 現在のページ数（０スタート）
    int numPage = _pageController.page!.round();
    // ページの総数
    int maxPage = 3;

    // 最初のページへ戻る
    if (numPage == maxPage -1) {
      _pageController.animateToPage(
        0,
        duration: Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
    }
    //　次のページへ
    else {
      _pageController.nextPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
    }

  
  }

  @override
  //************************************************************************************** ウィジェットビルド
  Widget build(BuildContext context) {
    // ページの幅と高さを取得
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [

          //------------------------------------------------------------------ ページ
          PageView(
            controller: _pageController,
            children: [
              // 入力ページ
              Input(),
              // グラフページ
              Center(child: Text("新しいページ")),
              Center(child: Text("最後のページ")),
            ],
          ),

          // 2種類の書き方あり
          //------------------------------------------------------------------ ページ進むボタン（右）
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: screenWidth * 0.1,
              height: screenHeight,
              child: IconButton(
                icon:Opacity(
                  opacity: 0.0,
                  child : Icon(Icons.chevron_left, size: 24),
                ),   // アイコンサイズは適宜調整
                onPressed: pageForward,
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
              ),
            ),
          ),
          //------------------------------------------------------------------ ページ戻るボタン（左） まだ長方形になっていない
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: TextButton(
              onPressed: pageBack,
              child: Text(""),
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                //onSurface: Colors.transparent,
                minimumSize: Size(screenWidth * 0.1, screenHeight),
              )
            ),
          ),
          
          /*
          // 戻るボタン（左）
          Positioned(
            left: 10,
            child: IconButton(onPressed: pageBack, icon: const Icon(Icons.chevron_left))
          ),
          // 進むボタン（右）
          Positioned(
            right: 10,
            child: IconButton(onPressed: pageForward, icon: const Icon(Icons.chevron_right))
          ),
          */
        ],
      ),
    );
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////// Chalenderクラス
class Calender extends StatefulWidget {
  final Function(DateTime) onDateChange;
  const Calender({super.key, required this.onDateChange});
  @override
  _CalenderState createState() => _CalenderState();
}

class _CalenderState extends State<Calender> { 

  // 今日の日付取得
  DateTime date = DateTime.now();

  // 日付進める
  void _dateForward() {
    setState(() {
      date = date.add(const Duration(days: 1));
      widget.onDateChange(date);
    });
  }

  // 日付戻す
  void _dateBack() {
    setState(() {
      date = date.subtract(const Duration(days: 1));
      widget.onDateChange(date);
    });
  }

  // 日付選択
  Future<void> _dateSelect(BuildContext context)async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020), // 年（下限）
      lastDate: DateTime(2100),  // 年（上限）
    );
    // 選択されたら更新
    if (picked != null && picked != date) {
      setState(() {
        date = picked;
      });
    }
  }

  @override
  //************************************************************************************** ウィジェットビルド
  Widget build(BuildContext context) {
    return
    // ------------------------------------------------------------------ カレンダーの詳細（↓）
    Row(
      children: [
        //戻るボタン
        IconButton(
          onPressed: _dateBack,
          icon: const Icon(Icons.chevron_left),
          iconSize: 35,
        ),

        // 日付
        GestureDetector(
          onTap: () => _dateSelect(context),
          child: Text(
            DateFormat("yyyy/M/d").format(date),
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w400), // fontsize40
          ),
        ),

        // 進むボタン
        IconButton(
          onPressed: _dateForward,
          icon: const Icon(Icons.chevron_right),
          iconSize: 35,
        ),

      ],
    );
    // ------------------------------------------------------------------ カレンダーの詳細（↑）
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////// Inputクラス
class Input extends StatefulWidget {
  const Input({super.key});
  @override
  _InputState createState() => _InputState();
}

// 入力欄のStateクラス
class _InputState extends State<Input> {
  // テキストボックスのコントローラー
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  // カテゴリーのリスト
  final List<String> cateList = [
    "食費",
    "交通費",
    "医療費"
  ];
  // カテゴリーの初期値
  String? cateSelect = "食費";
  // カテゴリーを編集する関数
  void editCateList(BuildContext context) {  
    showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width - 40,
            height: MediaQuery.of(context).size.height - 400,
            padding: EdgeInsets.all(20),
            color: Colors.white,
            child: Text("カスタムダイアログ"))
        );
      },
      barrierDismissible: true, // 外側をクリックしたらダイアログを閉じる 
      barrierColor: Colors.transparent,

      //
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut
          ),
          child: child,
        );
      }
    );   
  }

  
  
  
  // 今日の日付取得
  DateTime date = DateTime.now();
  // 日付のハンドラー
  void _onDateChange(DateTime newDate) {
    setState(() {
      date = newDate;
    });
  }

  // 完了ボタンの挙動
  void _saveData() async {
    // DB書き込み
    /*
    await database!.insert("Expenses_App", {
      "date": DateFormat("yyyy/M/d").format(date),
      "amount": int.parse(_amountController.text),
      "category": cateSelect,
      "memo": _memoController.text,
      }
    );
    */

    // print出力
    await printDB();
  }

  // データベース出力
  Future<void> printDB() async {
    final Database db = await database!;
    final List<Map<String, dynamic>> results = await db.query("Expenses_App");
    print("DBを出力します…");
    for (var row in results){
      print(row);
    }
  }

  @override
  //************************************************************************************** ウィジェットビルド
  Widget build(BuildContext context) {
    return 
    Row(
      mainAxisAlignment: MainAxisAlignment.center,    // 横軸で中央寄せ      
      children: [

        // 空白
        SizedBox(width: 200),

        //--------------------------------------------------------------------------------------------------- 中央列のコンテナ（↓）
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // カレンダー
            Calender(onDateChange: _onDateChange),

            // 空白
            SizedBox(height: 32),

            Row(
              children: [
                // 配置の整合性を保つために
                Text('円', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500, color: Color.fromRGBO(0, 0, 0, 0))),
                SizedBox(width: 10),

                // 中央列
                Container(
                  width: 200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,    // 縦軸で中央寄せ
                    crossAxisAlignment: CrossAxisAlignment.center,  // 横軸で中央寄せ
                  
                    children: [            
                        // 金額入力欄
                        TextField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "金額",
                            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                            contentPadding: EdgeInsets.symmetric(vertical: 10) // 上下の隙間
                            ),
                          textAlign: TextAlign.center, //中央揃え
                          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500),
                        ),
                
                        // 空白
                        SizedBox(height: 32),
                
                        // カテゴリーのドロップダウン
                        Container(
                          width: double.infinity, // 横幅を最大に
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey), // ボーダーを追加
                            borderRadius: BorderRadius.circular(4), // 角を丸くする
                          ),
                
                          child: Row(
                            children: [
                              SizedBox(width: 55),
                              DropdownButtonHideUnderline( //ドロップダウンの線を消す
                                // ------------------------------------------------------------------ ドロップダウンの詳細（↓）
                                child: DropdownButton<String>(
                                  value: cateSelect,
                                  items: <String>[
                                    ...cateList,
                                    "編集"
                                  ].map<DropdownMenuItem<String>>(
                                      (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value, 
                                          child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                                        );
                                      }
                                    ).toList(),                      
                                  onChanged: (String? newValue) { 
                                    print(newValue);
                                    if(newValue == "編集") {
                                      editCateList(context);
                                    }else{
                                      setState(() {
                                        cateSelect = newValue;
                                      });
                                    }
                                  },
                                  

                                  /*                              
                                  onChanged: (String? value) {
                                    if (value == "edit"){
                                      
                                      String data = await editCateList(context);
                                    }
                                    else{
                                      setState(() {
                                        cateSelect = value;
                                      });
                                    }
                                  }, 
                                  */                             
                                ),
                                // ------------------------------------------------------------------ ドロップダウンの詳細（↑）
                              ),
                            ],
                          ),
                        ),
                        
                        // 空白
                        SizedBox(height: 32),
                
                        // メモ欄
                        TextField(
                          controller: _memoController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            //labelText: "金額",
                            hintText: "メモ",
                            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                            contentPadding: EdgeInsets.symmetric(vertical: 10) // 上下の隙間
                            ),
                          textAlign: TextAlign.center, //中央揃え
                          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500),
                        ),    
                //--------------------------------------------------------------------------------------------------- 中央列のコンテナ（↑）
                
                        // 空白
                        SizedBox(height: 32),
                  
                        // 完了ボタン
                        ElevatedButton(
                          onPressed: _saveData,
                          child: Text("完了"),
                          style: ElevatedButton.styleFrom()
                  
                          ),
                    ],
                  ),
                ),
                
                // 空白
                SizedBox(width: 10),
                // 円テキスト
                Column(
                  children: [
                    Text('円', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500)),
                    SizedBox(height: 30), // 微調整
                    SizedBox(height: 45),
                    SizedBox(height: 32),
                    SizedBox(height: 45),
                    SizedBox(height: 32),
                    SizedBox(height: 45),
                  ],
                )
              ],
            ),
          ],
        ),

      // 空白
      SizedBox(width: 200),
      ],   
    );
  }
}