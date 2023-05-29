import 'dart:convert';
import 'dart:typed_data';

import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:flutter/material.dart';

import 'package:eurocup_frontend/src/common.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AthleteDetailView extends StatefulWidget {
  const AthleteDetailView({super.key});
  static const routeName = '/athlete';

  @override
  State<AthleteDetailView> createState() => _AthleteDetailViewState();
}

class _AthleteDetailViewState extends State<AthleteDetailView> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController genderController = TextEditingController();

  bool editable = false;
  String? mode;

  @override
  Widget build(BuildContext context) {
    if (mode == null) {
      final args = ModalRoute.of(context)!.settings.arguments;
      mode = args == null ? 'r' : (args as Map)['mode'];
    }
    switch (mode) {
      case 'r':
        editable = false;
        break;
      case 'm':
        editable = true;
        break;
    }

    firstNameController.text = currentAthlete.firstName ?? '';
    lastNameController.text = currentAthlete.lastName ?? '';
    dateOfBirthController.text = currentAthlete.birthDate ?? '';
    genderController.text = currentAthlete.gender ?? '';

    return Scaffold(
        appBar: AppBar(
          title: Text('${currentAthlete.firstName} ${currentAthlete.lastName}'),
          actions: [
            Visibility(
              visible: !editable,
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    mode = 'm';
                  });
                },
              ),
            ),
            Visibility(
              visible: editable,
              child: IconButton(
                icon: const Icon(Icons.save),
                onPressed: () {
                  setState(() {
                    mode = 'r';
                    api.updateAthlete(currentAthlete);
                  });
                },
              ),
            ),
          ],
        ),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
              child: GestureDetector(
            child: FutureBuilder(
              future: currentAthlete.convertPhotoBase64(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasData) {
                  final String Str64 = snapshot.data!;
                  Uint8List bytesImage = const Base64Decoder().convert(Str64);
                  print(Str64);
                  if (Str64 != '') {
                    return Image.memory(
                      bytesImage,
                      width: 100,
                      height: 100,
                    );
                  }
                }
                return (const Text('No data'));
              },
            ),
            onTap: () {
              selectImageSource();
            },
          )),
          TextField(
            decoration: const InputDecoration(
              labelText: 'First Name',
            ),
            controller: firstNameController,
            enabled: editable,
            onChanged: (value) {
              currentAthlete.firstName = value;
            },
          ),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Last Name',
            ),
            controller: lastNameController,
            enabled: editable,
            onChanged: (value) {
              currentAthlete.lastName = value;
            },
          ),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Date of Birth',
            ),
            controller: dateOfBirthController,
            readOnly: true,
            enabled: editable,
            onTap: () async {
              if (!editable) {
                return;
              }
              DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(dateOfBirthController.text) ??
                      DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2101));

              if (pickedDate != null) {
                String formattedDate =
                    DateFormat('yyyy-MM-dd').format(pickedDate);

                setState(() {
                  dateOfBirthController.text = formattedDate;
                  currentAthlete.birthDate = dateOfBirthController.text;
                });
              }
            },
          ),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Gender',
            ),
            controller: genderController,
            enabled: editable,
            onChanged: (value) {
              currentAthlete.gender = value;
            },
          ),
        ]),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Visibility(
          visible: editable,
          child: FloatingActionButton(
              child: Icon(Icons.delete),
              backgroundColor: Colors.red,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Really??'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () {
                              api.deleteAthlete(currentAthlete);
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: const Text('Delete')),
                      ],
                    );
                  },
                );
                print('delete');
              }),
        ));
  }

  void selectImageSource() {
    showModalBottomSheet(
        context: context,
        builder: (context) => Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.camera),
                  title: Text(
                    'Camera',
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    selectImage(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_album),
                  title: Text(
                    'Gallery',
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    selectImage(context, ImageSource.gallery);
                  },
                ),
              ],
            ));
  }

  void selectImage(BuildContext context, ImageSource imageSource) async {
    final XFile? image = await ImagePicker().pickImage(source: imageSource);
    if (image != null) {
      List<int> imageBytes = await image.readAsBytes();
      setState(() {
        currentAthlete.photoBase64 = base64Encode(imageBytes);
      });
    }
  }
}
