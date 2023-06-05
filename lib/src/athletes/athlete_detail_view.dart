import 'dart:convert';
import 'dart:typed_data';

import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/widgets.dart';
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
    var photoUrl = "https://$imagePrefix/${currentAthlete.photo}";
    print('photo url: $photoUrl');

    return Scaffold(
        appBar: AppBar(
          title: Text(
              '${currentAthlete.firstName ?? ""} ${currentAthlete.lastName ?? ""}'),
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
        body: Container(
          decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/images/bck.jpg'),
                  fit: BoxFit.cover)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
                child: GestureDetector(
              child: imagePreview(photoUrl: photoUrl),
              onTap: () {
                if (editable) {
                  selectImageSource();
                }
              },
            )),
            TextField(
              textCapitalization: TextCapitalization.words,
              decoration: buildStandardInputDecorationWithLabel('First Name'),
              controller: firstNameController,
              enabled: editable,
              style: Theme.of(context).textTheme.displaySmall,
              onChanged: (value) {
                currentAthlete.firstName = value;
              },
            ),
            TextField(
              textCapitalization: TextCapitalization.words,
              decoration: buildStandardInputDecorationWithLabel('Last Name'),
              controller: lastNameController,
              enabled: editable,
              style: Theme.of(context).textTheme.displaySmall,
              onChanged: (value) {
                currentAthlete.lastName = value;
              },
            ),
            TextField(
              decoration:
                  buildStandardInputDecorationWithLabel('Date of Birth'),
              controller: dateOfBirthController,
              readOnly: true,
              enabled: editable,
              style: Theme.of(context).textTheme.displaySmall,
              onTap: () async {
                if (!editable) {
                  return;
                }
                DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.tryParse(dateOfBirthController.text) ??
                            DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now());

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
            (!editable)
                ? TextField(
                    decoration: buildStandardInputDecorationWithLabel('Gender'),
                    controller: genderController,
                    enabled: false,
                    style: Theme.of(context).textTheme.displaySmall,
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton(
                      enableFeedback: editable,
                      hint: const Text('Select Gender'),
                      value: currentAthlete.gender,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female'))
                      ],
                      onChanged: (value) {
                        setState(() {
                          currentAthlete.gender = value;
                        });
                      },
                      style: Theme.of(context).textTheme.displaySmall,
                      padding:
                          const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                    ),
                  )
          ]),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Visibility(
          visible: editable,
          child: FloatingActionButton(
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
              },
              child: const Icon(Icons.delete)),
        ));
  }

  void selectImageSource() {
    showModalBottomSheet(
        context: context,
        builder: (context) => Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera),
                  title: Text(
                    'Camera',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    selectImage(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_album),
                  title: Text(
                    'Gallery',
                    style: Theme.of(context).textTheme.bodyLarge,
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
    final XFile? image = await ImagePicker()
        .pickImage(source: imageSource, maxHeight: 1024, maxWidth: 1024);
    if (image != null) {
      List<int> imageBytes = await image.readAsBytes();
      setState(() {
        currentAthlete.photoBase64 = base64Encode(imageBytes);
      });
    }
  }
}

class imagePreview extends StatelessWidget {
  const imagePreview({
    super.key,
    required this.photoUrl,
  });

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    if (currentAthlete.photoBase64 != '') {
      Uint8List bytesImage =
          const Base64Decoder().convert(currentAthlete.photoBase64);
      if (currentAthlete.photoBase64 != '') {
        return Image.memory(
          bytesImage,
          width: 256,
          height: 256,
        );
      }
    } else if (currentAthlete.photo != null && currentAthlete.photo != "") {
      return imageFromUrl(photoUrl: photoUrl);
    } 
    {
      return const imageUnknown();
    }

    // return FutureBuilder(
    //   future: currentAthlete.convertPhotoBase64(),
    //   builder: (context, snapshot) {
    //     if (snapshot.connectionState == ConnectionState.waiting) {
    //       return const Center(child: CircularProgressIndicator());
    //     }
    //     if (snapshot.hasData) {
    //       final String Str64 = snapshot.data!;
    //       Uint8List bytesImage = const Base64Decoder().convert(Str64);
    //       print(Str64);
    //       if (Str64 != '') {
    //         return Image.memory(
    //           bytesImage,
    //           width: 256,
    //           height: 256,
    //         );
    //       }
    //     }
    //     return Image.asset(
    //       'assets/images/unknown.png',
    //       width: 256,
    //       height: 256,
    //     );
    //   },
    // );
  }
}

class imageFromUrl extends StatelessWidget {
  const imageFromUrl({
    super.key,
    required this.photoUrl,
  });

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      photoUrl,
      width: 256,
      height: 256,
    );
  }
}

class imageUnknown extends StatelessWidget {
  const imageUnknown({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/unknown.png',
      width: 256,
      height: 256,
    );
  }
}
