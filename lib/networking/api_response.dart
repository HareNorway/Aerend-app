class ApiResponse<T> {
  Status? status;

  T? data;

  String? message;

  String? provider;

  double? progress;

  ApiResponse.loading({this.provider, this.progress}) : status = Status.loading;

  ApiResponse.completed([this.data]) : status = Status.completed;

  ApiResponse.error([this.message]) : status = Status.error;

  @override
  String toString() {
    return "Status : $status \n Message : $message \n Data : $data";
  }
}

enum Status { loading, completed, error }
