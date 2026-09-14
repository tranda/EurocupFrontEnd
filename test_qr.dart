import 'lib/src/qr_scanner/qr_code_util.dart';

void main() {
  var qr = QrCodeUtil.generate(athleteId: 3681, clubId: 1);
  print('Generated QR: $qr');
  var id = QrCodeUtil.verify(qr);
  print('Verified ID: $id');
}
