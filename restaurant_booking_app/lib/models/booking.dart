class Booking {
  final int? id;
  final int userId;
  final int packageId;
  final String eventDate;
  final String eventTime;
  final int numberOfGuests;
  final double totalPrice;
  final String status;
  final String? serviceCustomizations; // JSON string for customizations

  Booking({
    this.id,
    required this.userId,
    required this.packageId,
    required this.eventDate,
    required this.eventTime,
    required this.numberOfGuests,
    required this.totalPrice,
    required this.status,
    this.serviceCustomizations,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'packageId': packageId,
      'eventDate': eventDate,
      'eventTime': eventTime,
      'numberOfGuests': numberOfGuests,
      'totalPrice': totalPrice,
      'status': status,
      'serviceCustomizations': serviceCustomizations,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      packageId: map['packageId'] as int,
      eventDate: map['eventDate'] as String,
      eventTime: map['eventTime'] as String,
      numberOfGuests: map['numberOfGuests'] as int,
      totalPrice: map['totalPrice'] as double,
      status: map['status'] as String,
      serviceCustomizations: map['serviceCustomizations'] as String?,
    );
  }

  Booking copyWith({
    int? id,
    int? userId,
    int? packageId,
    String? eventDate,
    String? eventTime,
    int? numberOfGuests,
    double? totalPrice,
    String? status,
    String? serviceCustomizations,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      packageId: packageId ?? this.packageId,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      serviceCustomizations:
          serviceCustomizations ?? this.serviceCustomizations,
    );
  }
}
