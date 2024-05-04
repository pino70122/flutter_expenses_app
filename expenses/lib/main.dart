import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';       // 日付
import 'package:flutter_localizations/flutter_localizations.dart'; //日本語化
import 'package:flutter/services.dart';


void main() {
  //debugPaintSizeEnabled = true;
  runApp(const MyApp());
}

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

      // レイアウト
      home: Scaffold(
        appBar: AppBar(title: Text("支出入力"),),
        body: Input(),
      ));
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////// カレンダー
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

/////////////////////////////////////////////////////////////////////////////////////////////////// すべての親
class Input extends StatefulWidget {
  const Input({super.key});
  @override
  _InputState createState() => _InputState();
}

//入力欄
class _InputState extends State<Input> {
  // カテゴリーのリスト
  final List<String> cateList = [
    "食費",
    "交通費",
    "医療費"
  ];
  // カテゴリーの初期値
  String cateSelect = "食費";
  
  // 今日の日付取得
  DateTime dateSelect = DateTime.now();
  // 日付のハンドラー
  void _onDateChange(DateTime newDate) {
    setState(() {
      dateSelect = newDate;
    });
  }

  @override

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

            Container(
              width: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,    // 縦軸で中央寄せ
                crossAxisAlignment: CrossAxisAlignment.center,  // 横軸で中央寄せ
              
                children: [            
                    // 金額入力欄
                    TextField(
                      controller: TextEditingController(),
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
                              items: cateList.map<DropdownMenuItem<String>>(
                                (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value, 
                                    child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500))
                                  );
                                }
                              ).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  cateSelect = value!;
                                });
                              },  
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
                      controller: TextEditingController(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        //labelText: "金額",
                        hintText: "メモ",
                        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                        contentPadding: EdgeInsets.symmetric(vertical: 10) // 上下の隙間
                        ),
                      textAlign: TextAlign.center, //中央揃え
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),    
            //--------------------------------------------------------------------------------------------------- 中央列のコンテナ（↑）
            
                    // 空白
                    SizedBox(height: 32),
              
                    // 完了ボタン
                    ElevatedButton(
                      onPressed: (){},
                      child: Text("完了"),
                      style: ElevatedButton.styleFrom()
              
                      ),
                ],
              ),
            ),
          ],
        ),

      // 空白
      SizedBox(width: 200),

      ],

      
    );
  }
}

class TweetTile extends StatelessWidget {
  const TweetTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding( 
      padding: const EdgeInsets.all(8.0),
    
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          CircleAvatar(backgroundImage: AssetImage("assets/profile.jpg"),),
          
          SizedBox(width: 8,),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
    
              Row(
                children: [
                  Text("こんぶ＠Flutter大学"),
                  SizedBox(width: 8,),
                  Text("2022/05/05"),
                ],
                ),
                
              SizedBox(height: 4),
              Text("最高でした。"),
              IconButton(onPressed: (){}, icon: Icon(Icons.favorite_border)),
    
            ],
          ),
        ],
      ),
    );
  }
}