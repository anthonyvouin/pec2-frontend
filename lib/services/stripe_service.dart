import 'package:http/http.dart' as http;

class StripeService {
  StripeService._();

  static final StripeService instance = StripeService._();

  Future<void> makePayment() async {
    try {

    } catch (e) {
      print(e);
    }
  }


  Future<String?> _createPaymentIntent(int amount, String currency) async {
    try {
      Map<String, dynamic> data = {
        "amount": _calculateAmount(amount),
        "currency": currency
      };

      // var response = await http.post(uri, headers: headers, body: data);
    } catch (e) {
      print(e);
    }
  }

  String _calculateAmount(int amount) {
    return (amount * 100).toString();
  }
}
