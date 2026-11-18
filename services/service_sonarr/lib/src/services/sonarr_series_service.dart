import '../generated/api/raw_series_api.dart';
import '../generated/api/raw_series_lookup_api.dart';
import '../generated/models/series_resource.dart';
import '../generated/responses/sonarr_exception.dart';
import 'package:core_models/core_models.dart';

/// High-level service wrapper for Sonarr Series operations.
class SonarrSeriesService {
  final RawSeriesApi _rawSeriesApi;
  final RawSeriesLookupApi _rawSeriesLookupApi;

  SonarrSeriesService(this._rawSeriesApi, this._rawSeriesLookupApi);

  /// Retrieves all series monitored in Sonarr.
  Future<List<SeriesResource>> getSeries({String? tvdbId}) async {
    final response = await _rawSeriesApi.getSeries(tvdbId: tvdbId);
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    if (response.error != null) {
      throw SonarrException(
        response.error!.message ?? S.t('failedToFetchSeries'),
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    throw SonarrException(S.t('failedToFetchSeries'), statusCode: response.statusCode);
  }

  /// Retrieves a specific series by ID.
  Future<SeriesResource?> getSeriesById(String id) async {
    final response = await _rawSeriesApi.getSeriesById(id: id);
    if (response.isSuccess) {
      return response.data;
    }
    if (response.error != null) {
      throw SonarrException(
        response.error!.message ?? S.t('failedToFetchSeries'),
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    throw SonarrException(S.t('failedToFetchSeries'), statusCode: response.statusCode);
  }

  /// Searches for series by term.
  Future<List<SeriesResource>> searchSeries(String term) async {
    final response = await _rawSeriesLookupApi.getSeriesLookup(term: term);
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    if (response.error != null) {
      throw SonarrException(
        response.error!.message ?? S.t('seriesLookupFailed'),
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    throw SonarrException(S.t('seriesLookupFailed'), statusCode: response.statusCode);
  }
}
