import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bloc/bloc.dart';
import 'package:latlong/latlong.dart';
import './bloc.dart';

class CompanyBloc extends Bloc<CompanyEvent, CompanyState> {
  @override
  CompanyState get initialState => CompanyUninitialized();

  @override
  Stream<CompanyState> mapEventToState(
    CompanyEvent event,
  ) async* {
    if (event is FetchCompanies) {
      try {
        if (currentState is CompanyUninitialized) {
          final companies = await _fetchCompanies();
          yield CompanyLoaded(companies);
          return;
        }
      } catch (_) {
        yield CompanyError();
      }
    }
  }

  Future<List> _fetchCompanies() async {
    QuerySnapshot companiesSnapshotCache = await Firestore.instance
        .collection('companies')
        .getDocuments(source: Source.cache);

    var companiesList;
    var companies = [];

    if (companiesSnapshotCache.documents.length > 0) {
      print("CACHE FOUND");
      companiesList = companiesSnapshotCache.documents;
    } else {
      print("NO CACHE FOUND");
      print("Retrieving");
      QuerySnapshot companiesSnapshot =
          await Firestore.instance.collection('companies').getDocuments();
      companiesList = companiesSnapshot.documents;
    }

    companiesList.forEach((company) {
      company.data['branches'].forEach((geoPoint) {
        companies.add({
          'data': company.data,
          'location': LatLng(
            geoPoint.latitude,
            geoPoint.longitude,
          ),
        });
      });
    });

    return companies;
  }
}
