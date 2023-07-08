import 'package:flutter/material.dart';
import 'common.dart';

const String appTitle = 'Events Platform';

AppBar appBar({String? title}) {
  return AppBar(
    title: Center(
      // child: Expanded(
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(title ?? appTitle)),
      // )
    ),
  );
}

AppBar appBarWithWidget(Widget? widget) {
  return AppBar(
    title: Center(child: widget),
  );
}

AppBar appBarWithImageAndTitle(String? image, String? title) {
  return AppBar(
      title: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      (image != null) ? Image.asset(imagesPath + image) : Container(),
      SizedBox(width: horizontalPadding),
      Expanded(
          child:
              FittedBox(fit: BoxFit.scaleDown, child: Text(title ?? appTitle))),
      SizedBox(width: horizontalPadding),
    ],
  ));
}

AppBar appBarWithEdit(void Function()? onTap, {String? title}) {
  return AppBar(
    title: Center(
        // child: Expanded(
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(title ?? appTitle))
        // )
        ),
    actions: [IconButton(onPressed: onTap, icon: const Icon(Icons.edit))],
  );
}

AppBar appBarWithAction(void Function()? onTap,
    {String? title, IconData? icon}) {
  return AppBar(
    title: Center(
        child:
            FittedBox(fit: BoxFit.scaleDown, child: Text(title ?? appTitle))),
    actions: [IconButton(onPressed: onTap, icon: Icon(icon))],
  );
}

AppBar appBarWithImageAndTitleAndAction(void Function()? onTap,
    {IconData? icon, String? image, String? title}) {
  return AppBar(
    title: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        (image != null) ? Image.asset(imagesPath + image) : Container(),
        // SizedBox(width: horizontalPadding),
        Expanded(
          child:
              FittedBox(fit: BoxFit.scaleDown, child: Text(title ?? appTitle)),
        ),
        SizedBox(width: horizontalPadding),
      ],
    ),
    actions: [IconButton(onPressed: onTap, icon: Icon(icon))],
  );
}

InputDecoration buildInputDecoration(String hintText, IconData icon) {
  return InputDecoration(
    prefixIcon: Icon(icon, color: Color.fromRGBO(50, 62, 72, 1.0)),
    hintText: hintText,
    contentPadding: EdgeInsets.fromLTRB(20.0, 0.0, 0.0, 0.0),
    border:
        OutlineInputBorder(borderRadius: BorderRadius.circular(cornerRadius)),
  );
}

InputDecoration buildInputDecorationWithSuffix(
    String hintText, IconData icon, IconButton iconButton) {
  return InputDecoration(
    prefixIcon: Icon(icon, color: Color.fromRGBO(50, 62, 72, 1.0)),
    suffixIcon: iconButton,
    hintText: hintText,
    contentPadding: EdgeInsets.fromLTRB(20.0, 0.0, 0.0, 0.0),
    border:
        OutlineInputBorder(borderRadius: BorderRadius.circular(cornerRadius)),
  );
}

InputDecoration buildStandardInputDecoration(String? hint) {
  return InputDecoration(
    fillColor: Colors.white,
    filled: true,
    hintText: hint,
    contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
    border:
        OutlineInputBorder(borderRadius: BorderRadius.circular(cornerRadius)),
  );
}

InputDecoration buildStandardInputDecorationWithLabel(String? label) {
  return InputDecoration(
    labelText: label,
    contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
    // border:
    //     OutlineInputBorder(borderRadius: BorderRadius.circular(cornerRadius)),
  );
}

InputDecoration buildPasswordInputDecoration(String? hint) {
  return InputDecoration(
    fillColor: Colors.white,
    filled: true,
    hintText: hint,
    contentPadding: EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0),
    border:
        OutlineInputBorder(borderRadius: BorderRadius.circular(cornerRadius)),
  );
}

MaterialButton longButtons(String title, Function() fun,
    {Color color: Colors.blue, Color textColor = Colors.white}) {
  return MaterialButton(
    onPressed: fun,
    textColor: textColor,
    color: color,
    height: 44,
    minWidth: 300,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(cornerRadius))),
    child: SizedBox(
      width: double.infinity,
      child: Text(
        title,
        textAlign: TextAlign.center,
      ),
    ),
  );
}

Row loadingRow() {
  return const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[CircularProgressIndicator(), Text("Please wait...")],
  );
}

Widget busyOverlay(BuildContext context) {
  return SizedBox(
    width: MediaQuery.of(context).size.width,
    height: MediaQuery.of(context).size.height,
    child: GestureDetector(
        child: const Center(child: CircularProgressIndicator())),
  );
}

void showInfoDialog(BuildContext context, String title, String description,
    void Function()? callback) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
            title: Text(title),
            content: Text(description),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (callback != null) {
                    callback();
                  }
                },
              ),
            ],
          ));
}

BoxDecoration sectionDecoration() {
  return BoxDecoration(border: Border.all());
}

BoxDecoration bckDecoration() {
  return const BoxDecoration(
    image: DecorationImage(
        image: AssetImage('assets/images/bck.jpg'),
        fit: BoxFit.cover,
        ),
  );
}

BoxDecoration naslovnaDecoration() {
  return const BoxDecoration(
    image: DecorationImage(
        image: AssetImage('assets/images/naslovna-bck.jpg'),
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter),
  );
}
