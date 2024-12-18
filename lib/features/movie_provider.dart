import 'package:flutter/material.dart';

class MovieProvider with ChangeNotifier {
  List<Map<String, dynamic>> _movieList = [];

  // Getter
  List<Map<String, dynamic>> get movieList => _movieList;

  // Setter
  void setMovieList(List<Map<String, dynamic>> movieList) {
    _movieList = movieList;
    notifyListeners();
  }
}
