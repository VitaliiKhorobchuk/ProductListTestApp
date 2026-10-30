import 'package:equatable/equatable.dart';

enum CatalogFailureKind { connection, timeout, server, notFound, invalidData }

class CatalogFailure extends Equatable implements Exception {
  const CatalogFailure(this.kind, this.message);

  final CatalogFailureKind kind;
  final String message;

  @override
  List<Object> get props => [kind, message];

  @override
  String toString() => 'CatalogFailure($kind): $message';
}
