import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../commonView/common_view.dart';
import '../../../constant/constant.dart';
import '../../../main.dart';
import 'reorder_bloc.dart';
import 'reorder_dl.dart';

class Reorder extends StatefulWidget {
  final int? orderId;

  const Reorder({super.key, this.orderId});

  @override
  State<Reorder> createState() => _ReorderState();
}

class _ReorderState extends State<Reorder> {
  late ReorderBloc reorderBloc;

  @override
  void didChangeDependencies() {
    reorderBloc = ReorderBloc();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ApiResponse<ReorderDl>>(
        stream: reorderBloc.subject,
        builder: (context, snapshot) {
          var isLoading = snapshot.hasData && snapshot.data?.status == Status.loading;
          return CustomRoundedButton(
            context,
            languages.repeat,
            () {
              reorderBloc.getReorderDetail(widget.orderId!);
            },
            margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, end: deviceWidth * 0.02),
            setBorder: true,
            setProgress: isLoading,
            textSize: textSizeSmall,
            progressSize: 0.02,
            padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, end: deviceWidth * 0.02),
            minHeight: commonBtnHeightSmallest,
            minWidth: 1,
          );
        });
  }
}
