class StoreCategoryService {

  static String getCategory(String name) {

    final n = name.toLowerCase();

    if (n.contains("lotus") ||
        n.contains("aeon") ||
        n.contains("hypermarket")) {
      return "Hypermarket";
    }

    if (n.contains("family") ||
        n.contains("7-eleven") ||
        n.contains("speedmart") ||
        n.contains("orange") ||
        n.contains("kk")) {
      return "Convenience";
    }

    return "Grocery";
  }

}