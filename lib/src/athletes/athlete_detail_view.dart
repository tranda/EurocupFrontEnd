import 'dart:convert';
import 'dart:typed_data';

import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/model/athlete/athlete.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';

import 'package:eurocup_frontend/src/common.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:file_picker/file_picker.dart';

class AthleteDetailView extends StatefulWidget {
  const AthleteDetailView({super.key});
  static const routeName = '/athlete';

  @override
  State<AthleteDetailView> createState() => _AthleteDetailViewState();
}

class _AthleteDetailViewState extends State<AthleteDetailView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController genderController = TextEditingController();

  bool editable = false;
  String? mode;
  bool allowEdit = true;
  late Athlete currentAthlete;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (mode == null) {
      mode = args == null ? 'r' : (args as Map)['mode'];
      allowEdit = args == null ? true : (args as Map)['allowEdit'] ?? true;
    }
    switch (mode) {
      case 'r':
        editable = false;
        break;
      case 'm':
        editable = true;
        break;
    }
    currentAthlete = (args as Map)['athlete'] as Athlete;
    firstNameController.text = currentAthlete.firstName ?? '';
    lastNameController.text = currentAthlete.lastName ?? '';
    dateOfBirthController.text = currentAthlete.birthDate ?? '';
    genderController.text = currentAthlete.gender ?? '';
    var photoUrl = "https://$imagePrefix/${currentAthlete.photo}";
    var certificateUrl =
        "https://$certificatePrefix/${currentAthlete.certificate}";
    // print('photo url: $photoUrl');

    return Scaffold(
        appBar: AppBar(
          title: Text(
              '${currentAthlete.firstName ?? ""} ${currentAthlete.lastName ?? ""}'),
          actions: [
            Visibility(
              visible: !editable && allowEdit,
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    mode = 'm';
                  });
                },
              ),
            ),
          ],
        ),
        body: Column(children: [
          Container(
            decoration: bckDecoration(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: GestureDetector(
                    child: imagePreview(photoUrl: photoUrl,  currentAthlete: currentAthlete),
                    onTap: () {
                      if (editable) {
                        selectImageSource();
                      }
                    },
                  )),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                    decoration:
                        buildStandardInputDecorationWithLabel('First Name'),
                    controller: firstNameController,
                    enabled: editable,
                    style: Theme.of(context).textTheme.displaySmall,
                    onChanged: (value) {
                      currentAthlete.firstName = value;
                    },
                  ),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                    decoration:
                        buildStandardInputDecorationWithLabel('Last Name'),
                    controller: lastNameController,
                    enabled: editable,
                    style: Theme.of(context).textTheme.displaySmall,
                    onChanged: (value) {
                      currentAthlete.lastName = value;
                    },
                  ),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
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
                        lastDate: DateTime.now(),
                        initialDatePickerMode: DatePickerMode.year,
                      );

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
                      ? TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required!';
                            }
                            return null;
                          },
                          decoration:
                              buildStandardInputDecorationWithLabel('Gender'),
                          controller: genderController,
                          enabled: false,
                          style: Theme.of(context).textTheme.displaySmall,
                        )
                      : DropdownButtonFormField(
                          hint: const Text('Select Gender'),
                          value: currentAthlete.gender,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                          items: const [
                            DropdownMenuItem(
                                value: 'Male', child: Text('Male')),
                            DropdownMenuItem(
                                value: 'Female', child: Text('Female'))
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
                  const SizedBox(
                    height: bigSpace,
                  ),
                  Visibility(
                    visible: !editable,
                    child: ListTile(
                      title: Text(
                        currentAthlete.category ?? "",
                        style: Theme.of(context).textTheme.displayLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: bigSpace,
                  ),
                  Visibility(
                    visible: currentAthlete.id != null,
                    child: Padding(
                      padding:  const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                      child: Row(
                        children: [
                          Text(
                            'Antidoping certificate: ',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          editable
                              ? ElevatedButton(
                                  onPressed: () {
                                    selectFile(context);
                                  },
                                  child: const Text('Upload'))
                              : currentAthlete.certificate == null
                                  ? Text(
                                      'missing',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall,
                                    )
                                  : ElevatedButton(
                                      onPressed: () => _launchUrl(certificateUrl),
                                      child: const Text('Open')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: bigSpace,
                  ),
                ],
              ),
            ),
          ),
          // ElevatedButton(
          //     onPressed: () => _launchUrl(certificateUrl), child: Text('Open')),
        ]),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Visibility(
          visible: editable,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              FloatingActionButton(
                backgroundColor: Colors.blue,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      mode = 'r';
                      api
                          .updateAthlete(currentAthlete)
                          .then((value) => Navigator.pop(
                                context,
                              ));
                    });
                  }
                },
                child: const Icon(Icons.save),
              ),
              FloatingActionButton(
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
                                api.deleteAthlete(currentAthlete).then((value) {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                });
                              },
                              child: const Text('Delete')),
                        ],
                      );
                    },
                  );
                  print('delete');
                },
                child: const Icon(Icons.delete),
              ),
            ],
          ),
        ));
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrlString(url)) {
      throw Exception('Could not launch $url');
    }
  }

  void selectImageSource() {
    showModalBottomSheet(
        backgroundColor: Colors.blue,
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

  void selectFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

    if (result != null) {
      List<int> fileBytes = result.files.single.bytes!;
      await api.uploadFile(currentAthlete.id!, fileBytes);
      setState(() {});
    } else {
      // User canceled the file selection
      print('File selection canceled.');
    }
  }
}

// ignore: camel_case_types
class imagePreview extends StatelessWidget {
  const imagePreview(
      {super.key, required this.photoUrl, required this.currentAthlete});

  final String photoUrl;
  final Athlete currentAthlete;

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

// ignore: camel_case_types
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

// ignore: camel_case_types
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
