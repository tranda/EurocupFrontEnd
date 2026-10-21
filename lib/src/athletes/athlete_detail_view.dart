import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/model/athlete/athlete.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import 'package:eurocup_frontend/src/common.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:file_picker/file_picker.dart';
import 'image_widget_web.dart' if (dart.library.io) 'package:flutter/material.dart';

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
 
  /// Style C section body: 16px padding, 12px gaps between fields.
  Widget _section(List<Widget> fields) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < fields.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            fields[i],
          ],
        ],
      ),
    );
  }

  /// Checkboxes laid out two per row, with the same 16px side padding.
  Widget _checkboxSection(List<Widget> tiles) {
    final rows = <Widget>[];
    for (int i = 0; i < tiles.length; i += 2) {
      rows.add(Row(
        children: [
          Expanded(child: tiles[i]),
          Expanded(
              child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox()),
        ],
      ));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(children: rows),
    );
  }

  /// One checkbox; disabled (read-only) unless the page is in edit mode.
  Widget _checkTile(String label, bool? value, void Function(bool) assign) {
    return CheckboxListTile(
      value: value ?? false,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: pageBlue,
      title: Text(label, style: Theme.of(context).textTheme.displaySmall),
      onChanged: (editable)
          ? (v) {
              setState(() {
                assign(v ?? false);
              });
            }
          : null,
    );
  }

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
    // Use direct URLs - images work with img tags despite CORS warnings
    var photoUrl = currentAthlete.photo != null && currentAthlete.photo!.isNotEmpty
        ? "https://$imagePrefix/${currentAthlete.photo}"
        : "";
    var certificateUrl = currentAthlete.certificate != null && currentAthlete.certificate!.isNotEmpty
        ? "https://$certificatePrefix/${currentAthlete.certificate}"
        : "";
    // Debug: photo url

    return Scaffold(
        appBar: AppBar(
          title: Text(
              '${currentAthlete.firstName ?? ""} ${currentAthlete.lastName ?? ""}'),
          actions: [
            Visibility(
              visible: !editable && currentAthlete.id != null,
              child: IconButton(
                icon: const Icon(Icons.qr_code),
                onPressed: () => _showQrCode(currentAthlete),
              ),
            ),
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
        body: Container(
          decoration: bckDecoration(),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageTitleBlock(
                    title: currentAthlete.id == null
                        ? 'New athlete'
                        : '${currentAthlete.firstName ?? ""} ${currentAthlete.lastName ?? ""}'
                            .trim(),
                    children: [
                      Center(
                          child: GestureDetector(
                        child: imagePreview(
                            photoUrl: photoUrl, currentAthlete: currentAthlete),
                        onTap: () {
                          if (editable) {
                            selectImageSource();
                          }
                        },
                      )),
                      if (!editable && (currentAthlete.category ?? '').isNotEmpty)
                        Text(
                          currentAthlete.category!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: pageBlue,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                    ],
                  ),
                  const ColoredPageHeader(title: 'Personal details'),
                  _section([
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                      decoration: pageFieldDecoration('First Name'),
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
                      decoration: pageFieldDecoration('Last Name'),
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
                      decoration: pageFieldDecoration('Date of Birth').copyWith(
                        suffixIcon: const Icon(Icons.calendar_today, color: pageBlue),
                      ),
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
                            decoration: pageFieldDecoration('Gender'),
                            controller: genderController,
                            enabled: false,
                            style: Theme.of(context).textTheme.displaySmall,
                          )
                        : DropdownButtonFormField(
                            decoration: pageFieldDecoration('Gender'),
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
                          ),
                  ]),
                  pageSectionGap,
                  const ColoredPageHeader(title: 'Boat positions'),
                  _checkboxSection([
                    _checkTile('Left Side', currentAthlete.leftSide, (v) {
                      currentAthlete.leftSide = v;
                    }),
                    _checkTile('Right Side', currentAthlete.rightSide, (v) {
                      currentAthlete.rightSide = v;
                    }),
                    _checkTile('Helm', currentAthlete.helm, (v) {
                      currentAthlete.helm = v;
                    }),
                    _checkTile('Drummer', currentAthlete.drummer, (v) {
                      currentAthlete.drummer = v;
                    }),
                  ]),
                  pageSectionGap,
                  const ColoredPageHeader(title: 'Roles'),
                  _checkboxSection([
                    _checkTile('Coach', currentAthlete.coach, (v) {
                      currentAthlete.coach = v;
                    }),
                    _checkTile('Official', currentAthlete.official, (v) {
                      currentAthlete.official = v;
                    }),
                    _checkTile('Media', currentAthlete.media, (v) {
                      currentAthlete.media = v;
                    }),
                    _checkTile('Supporter', currentAthlete.supporter, (v) {
                      currentAthlete.supporter = v;
                    }),
                  ]),
                  if (currentAthlete.id != null) ...[
                    pageSectionGap,
                    const ColoredPageHeader(title: 'Documents'),
                    _section([
                      Row(
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
                                  ? const StatusChip(
                                      label: 'missing', color: Colors.red)
                                  : ElevatedButton(
                                      onPressed: () =>
                                          _launchUrl(certificateUrl),
                                      child: const Text('Open')),
                        ],
                      ),
                    ]),
                  ],
                  const SizedBox(
                    height: bigSpace,
                  ),
                ],
              ),
            ),
          ),
        ),
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
                  // Debug: delete action
                },
                child: const Icon(Icons.delete),
              ),
            ],
          ),
        ));
  }

  Future<void> _showQrCode(Athlete athlete) async {
    // The backend signs the QR; the app never holds the key.
    final qrData = await api.getAthleteQrToken(athlete.id!);
    if (!mounted) return;
    if (qrData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load QR code')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${athlete.firstName} ${athlete.lastName}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        content: SizedBox(
          width: 280,
          height: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 250,
              ),
              const SizedBox(height: 8),
              Text(
                'ID: ${athlete.id}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _printQrCode(athlete, qrData);
            },
            child: const Text('Print'),
          ),
        ],
      ),
    );
  }

  Future<void> _printQrCode(Athlete athlete, String qrData) async {
    final fontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final ttf = pw.Font.ttf(fontData);
    final fontDataRegular = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttfRegular = pw.Font.ttf(fontDataRegular);

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  '${athlete.firstName} ${athlete.lastName}',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: ttf),
                ),
                pw.SizedBox(height: 20),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrData,
                  width: 200,
                  height: 200,
                ),
                pw.SizedBox(height: 10),
                pw.Text('ID: ${athlete.id}', style: pw.TextStyle(fontSize: 12, font: ttfRegular)),
              ],
            ),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  Future<void> _launchUrl(String url) async {
    var random = Random().nextInt(1000000);
    if (!await launchUrlString("$url?random=$random")) {
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
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
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
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
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
      // File selection canceled.
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
    } else if (photoUrl.isNotEmpty) {
      return imageFromUrl(photoUrl: photoUrl);
    }
    return const imageUnknown();

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
    // Use web-specific HTML rendering for web platform
    if (kIsWeb) {
      return WebImage(
        imageUrl: photoUrl,
        width: 256,
        height: 256,
      );
    }
    
    // For non-web platforms, use regular Image.network
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        photoUrl,
        width: 256,
        height: 256,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const imageUnknown();
        },
      ),
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
