import '../../sign_in/models/permission.dart';

/// Parsed result of the redirect back from the Data Exchange approval flow
/// (step 3). `granted` = user approved; any other `data_exchange_status`
/// value (including `cancel`) becomes [failure] (contract validated
/// against platform-sdk-react, `data-exchange.ts`
/// `parseDataExchangeCallback`).
enum DataExchangeStatus { granted, cancelled, failure }

class DataExchangeResult {
  DataExchangeResult({required this.status, this.grantedPermissions = const {}});

  final DataExchangeStatus status;
  final Set<YouVersionPermission> grantedPermissions;

  bool get isGranted => status == DataExchangeStatus.granted;
}
