import 'dart:async';
import 'package:flutter/material.dart';
import '../models/city_model.dart';
import '../services/firestore_service.dart';

class CitiesProvider extends ChangeNotifier {
  final FirestoreService _service;
  StreamSubscription<List<CityModel>>? _sub;

  CitiesProvider(this._service) {
    _listen();
  }

  List<CityModel> cities = [];
  bool isLoading = true;

  void _listen() {
    _sub = _service.watchCities().listen((data) {
      cities = data;
      isLoading = false;
      notifyListeners();
    });
  }

  List<CityModel> get activeCities => cities.where((c) => c.isActive).toList();

  Future<void> addCity(String nameEn, String nameUr) {
    return _service.addCity(CityModel(id: '', nameEn: nameEn, nameUr: nameUr));
  }

  Future<void> updateCity(CityModel city) => _service.updateCity(city);

  Future<void> deleteCity(String cityId) => _service.deleteCity(cityId);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
