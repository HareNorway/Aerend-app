
class CartItem {
  int prodId, prodQuantity, prodCustomizeSize;
  double prodTotalAmount;
  String prodCustomizeOption, prodCustomizeToppings, productName;

  CartItem({
    required this.prodId,
    required this.prodQuantity,
    required this.prodCustomizeSize,
    required this.prodTotalAmount,
    required this.prodCustomizeOption,
    required this.prodCustomizeToppings,
    required this.productName,
  });

  static CartItem? fromJson(dynamic json) {
    return json != null
        ? CartItem(
            prodId: json["prodId"],
            prodQuantity: json["prodQuantity"],
            prodCustomizeSize: json["prodCustomizeSize"],
            prodTotalAmount: json["prodTotalAmount"],
            prodCustomizeOption: json["prodCustomizeOption"],
            prodCustomizeToppings: json["prodCustomizeToppings"],
            productName: json["productName"])
        : null;
  }

  dynamic toJson() {
    return {
      "prodId": prodId,
      "prodQuantity": prodQuantity,
      "prodCustomizeSize": prodCustomizeSize,
      "prodTotalAmount": prodTotalAmount,
      "prodCustomizeOption": prodCustomizeOption,
      "prodCustomizeToppings": prodCustomizeToppings,
      "productName": productName,
    };
  }
}
