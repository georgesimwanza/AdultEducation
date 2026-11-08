import 'package:flutter/material.dart';

import 'package:adult/screens/color.dart';

/// Paginated table for long admin lists on desktop, styled with the app's
/// design tokens. Phones and tablets keep their card lists.
class AdminDataTable extends StatelessWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.rowsPerPage = 10,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final int rowsPerPage;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: padding,
      child: Theme(
        data: theme.copyWith(
          cardTheme: CardThemeData(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: EduColors.border),
            ),
          ),
          dividerColor: EduColors.border,
          dataTableTheme: DataTableThemeData(
            headingRowColor: WidgetStateProperty.all(EduColors.background),
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: EduColors.textSecondary,
            ),
            dataTextStyle: TextStyle(
              fontSize: 13.5,
              color: EduColors.textPrimary,
            ),
            dataRowColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.hovered)
                  ? EduColors.primarySoft
                  : Colors.white,
            ),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: PaginatedDataTable(
            columns: columns,
            source: _RowsSource(rows),
            rowsPerPage: rows.isEmpty
                ? 1
                : (rows.length < rowsPerPage ? rows.length : rowsPerPage),
            showCheckboxColumn: false,
            columnSpacing: 28,
            horizontalMargin: 20,
            showFirstLastButtons: true,
          ),
        ),
      ),
    );
  }
}

class _RowsSource extends DataTableSource {
  _RowsSource(this.rows);
  final List<DataRow> rows;

  @override
  DataRow? getRow(int index) => index < rows.length ? rows[index] : null;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => rows.length;

  @override
  int get selectedRowCount => 0;
}

/// Ellipsised table cell text with a max width, so long values never
/// stretch or overflow a column.
class TableText extends StatelessWidget {
  const TableText(this.text, {super.key, this.maxWidth = 260, this.style});

  final String text;
  final double maxWidth;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
