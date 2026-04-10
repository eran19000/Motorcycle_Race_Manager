/// One WGS84 point for a circuit outline (const-friendly for data files).
class TrackLatLng {
  const TrackLatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}
