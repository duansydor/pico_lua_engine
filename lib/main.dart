import 'package:flutter/material.dart';
import 'package:lua_dardo/lua.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.tealAccent),
      ),
      home: const MyHomePage(title: 'Mini Engine'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _codeController = TextEditingController();
  late LuaState state;
  String soma = "";
  Timer? _gameLoop;
  Color _corDeFundo = Colors.white;

  @override
  void initState() {
    super.initState();
    state = LuaState.newState();
    state.openLibs();
    state.register("set_bg", changeBackgroundColor);
    rootBundle.loadString('lib/assets/logic.lua').then((content){
      //funcao de somar, apenas para teste
      state.doString(content);
      // state.getGlobal("somar");
      // state.pushInteger(1);
      // state.pushInteger(10);
      // state.call(2,1);

      _gameLoop = Timer.periodic(const Duration(seconds: 1), (timer){
        state.getGlobal("change_color");
        if(state.isFunction(-1)){
          state.pCall(0, 0, 0);
        }else{
          state.pop(1);
        }
      });

      setState(() {
        // soma = state.toInteger(-1).toString();
        
      });
    });   
  }
  // para o timer quando fecha o app
  @override
  void dispose() {
    _gameLoop?.cancel();
    super.dispose();
  }
  //codigo para o code controller
  void _executeCode(){
    String code = _codeController.text;
    try{
      state.doString(code);
      print("codigo executado com sucesso");
    }catch(e){
      print("Erro no codigo LUA: $e");
    }
  }
  int changeBackgroundColor(LuaState ls){
    String corNome = ls.toStr(-1) ?? "white";
    Map<String, Color> cores = {
      "red": Colors.red,
      "blue": Colors.blue,
      "green": Colors.green,
      "teal": Colors.teal,
      "black": Colors.black,
    };

  setState(() {
    _corDeFundo = cores[corNome] ?? Colors.white;
  });
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: _corDeFundo,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _codeController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent),
                  decoration: InputDecoration(
                    fillColor: Colors.black.withAlpha(80),
                    filled: true,
                    hintText: "Code here bro",
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: const OutlineInputBorder(),
                  ),
                ),
              )
            ),
            ElevatedButton(
              onPressed: _executeCode,
              child: const Text("Rodar o codigo"),
              ),
          ],
        ),
      ),
    );
  }
}
