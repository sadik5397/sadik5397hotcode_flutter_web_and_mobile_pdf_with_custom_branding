import 'dart:async';
import 'dart:html' as html;
import 'dart:math';

import 'package:bijoy_helper/bijoy_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'data.dart';
import 'variables.dart';

Future<void> main() async => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, title: 'Web PDF', theme: ThemeData(useMaterial3: true), home: const MyHomePage());
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  dynamic data;
  var pdf = pw.Document();
  dynamic englishFont;
  dynamic banglaFont;
  int elementPerPage = 18;

  defaultInit() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() => data = jsonData);
  }

  Future printNow() async {
    englishFont = await rootBundle.load("fonts/Roboto-Regular.ttf");
    banglaFont = await rootBundle.load("fonts/Kalpurush-ANSI.ttf");
    // await writeOnPdf();
    await writeOnPdfWithBranding();
    await savePdf();
  }

  writeOnPdf() async {
    pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4, orientation: pw.PageOrientation.portrait, margin: const pw.EdgeInsets.all(12), build: (pw.Context context) => [pdfElementBasic(pageNo: 1, totalPageCount: 1)]));
  }

  writeOnPdfWithBranding() async {
    final ByteData image = await rootBundle.load('assets/document_footer.png');
    Uint8List imageData = (image).buffer.asUint8List();
    int totalPageWillBe = (max<int>(data["income"].length, data["expense"].length) / elementPerPage).ceil();
    for (int i = 0; i < totalPageWillBe; i++) {
      pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          orientation: pw.PageOrientation.portrait,
          margin: const pw.EdgeInsets.all(0),
          build: (pw.Context context) => pdfElementWithBranding(pdfElement: pdfElementBasic(pageNo: i, totalPageCount: totalPageWillBe), imageData: imageData, pageNo: i, totalPageCount: totalPageWillBe)));
    }
  }

  Future savePdf() async {
    if (!kIsWeb) {
      //region for ANDROID & IOS
      //   if (await Permission.storage.request().isGranted) {
      //     var status = await Permission.storage.status;
      //     if (status.isDenied) print("Storage write access permission has been denied");
      //     if (status.isRestricted) print("The OS restricts access, for example because of parental controls");
      //     if (status.isGranted) print("Report Saved in Download Folder as PDF Document");
      //     String path = Platform.isIOS ? (await getApplicationDocumentsDirectory()).path : await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS);
      //     String fileName = "Report_on_by_Hi_Society.pdf";
      //     final file = File("$path/$fileName");
      //     await file.writeAsBytes(await pdf.save());
      //   } else {
      //     print("Storage access REQUESTED, Please try again");
      //     await [Permission.storage].request();
      //   }
      //endregion
    } else {
      //region for WEB
      // Generate PDF content (replace this with your actual PDF generation logic)
      final pdfContent = pdf;

      // Convert PDF content to Uint8List
      final Uint8List pdfBytes = await pdfContent.save();

      // Create a Blob from the PDF bytes
      final blob = html.Blob([pdfBytes]);

      // Get the URL for the Blob
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create a link element
      html.AnchorElement(href: url)
        ..setAttribute("download", "Report_on_by_Hi_Society.pdf")
        ..click();

      // Revoke the URL to release memory
      html.Url.revokeObjectUrl(url);
      //endregion
    }
  }

  @override
  void initState() {
    super.initState();
    defaultInit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(backgroundColor: Colors.blueAccent, title: const Text("Adjusted Monthly Statement February 2024", style: TextStyle(color: Colors.white)), centerTitle: true),
        body: ListView(children: [
          Container(
              padding: primaryPadding,
              alignment: Alignment.center,
              color: themeOf,
              width: double.maxFinite,
              child: Column(children: [SelectableText("buildingName", style: semiBold16Black), SelectableText("buildingAddress", style: normal12Black, textAlign: TextAlign.center)])),
          data == null
              ? Container(padding: primaryPadding * 2, alignment: Alignment.center, child: const Text("Loading..."))
              : Container(
                  color: trueWhite,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      primaryDataTable(
                          titleHeader: "Incomes",
                          valueHeader: "Amount",
                          rows: List.generate(
                              data["income"].length, (index) => balanceSheetDataTile(context: context, alternate: index.isOdd, title: data["income"][index]["title"], amount: data["income"][index]["amount"]))),
                      primaryDataTable(
                          titleHeader: "Expenses",
                          valueHeader: "Amount",
                          rows: List.generate(data["expense"].length,
                              (index) => balanceSheetDataTile(context: context, alternate: index.isOdd, title: data["expense"][index]["title"], amount: data["expense"][index]["amount"]))),
                    ]),
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: primaryPaddingValue),
                        child: SelectableText('Statement Created on: ${primaryDateTime(DateTime.now().toString())}', style: normal12Black50, textAlign: TextAlign.center)),
                  ])),
          Container(height: 6, color: primaryColor, width: double.maxFinite),
          Padding(padding: primaryPadding, child: ElevatedButton(onPressed: () async => await printNow(), child: const Text("Create PDF")))
        ]));
  }

  pw.Column pdfElementBasic({required int pageNo, required int totalPageCount}) {
    return pw.Column(mainAxisSize: pw.MainAxisSize.min, children: [
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(
            child: pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey500),
          headers: ["Incomes", "Amount"],
          // cellHeight: 16,
          data: List.generate(
              (pageNo + 1) == totalPageCount ? data["income"].length - pageNo * elementPerPage : elementPerPage,
              (index) => [
                    pw.Text(webPdfCheck(data["income"][pageNo * elementPerPage + index]["title"]),
                        style: pw.TextStyle(font: pw.Font.ttf(isEnglish(data["income"][pageNo * elementPerPage + index]["title"]) ? englishFont : banglaFont), fontSize: 9)),
                    pw.Text(webPdfCheck(data["income"][pageNo * elementPerPage + index]["amount"]),
                        style: pw.TextStyle(font: pw.Font.ttf(isEnglish(data["income"][pageNo * elementPerPage + index]["amount"]) ? englishFont : banglaFont), fontSize: 9)),
                  ]),
          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueAccent),
          cellAlignment: pw.Alignment.center,
        )),
        pw.SizedBox(width: 4),
        pw.Expanded(
            child: pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey500),
          headers: ["Expenses", "Amount"],
          // cellHeight: 16,
          data: List.generate(
              (pageNo + 1) == totalPageCount ? data["expense"].length - pageNo * elementPerPage : elementPerPage,
              (index) => [
                    pw.Text(webPdfCheck(data["expense"][pageNo * elementPerPage + index]["title"]),
                        style: pw.TextStyle(font: pw.Font.ttf(isEnglish(data["expense"][pageNo * elementPerPage + index]["title"]) ? englishFont : banglaFont), fontSize: 9)),
                    pw.Text(webPdfCheck(data["expense"][pageNo * elementPerPage + index]["amount"]),
                        style: pw.TextStyle(font: pw.Font.ttf(isEnglish(data["expense"][pageNo * elementPerPage + index]["amount"]) ? englishFont : banglaFont), fontSize: 9)),
                  ]),
          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueAccent),
          cellAlignment: pw.Alignment.center,
        ))
      ]),
      pw.SizedBox(height: 24),
      pw.Text("Generated on ${primaryDateTime(DateTime.now().toString())}", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
        pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 4),
            margin: const pw.EdgeInsets.only(top: 36),
            child: pw.Text("Auditor", style: const pw.TextStyle(fontSize: 8)),
            decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey600, width: 1.0)))),
        pw.SizedBox(width: 4),
        pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 4),
            margin: const pw.EdgeInsets.only(top: 36),
            child: pw.Text("Secretary", style: const pw.TextStyle(fontSize: 8)),
            decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey600, width: 1.0)))),
      ])
    ]);
  }

  List<pw.Widget> pdfElementWithBranding({required pw.Widget pdfElement, required Uint8List imageData, required int pageNo, required int totalPageCount}) {
    return <pw.Widget>[
      pw.Padding(
          padding: const pw.EdgeInsets.all(32).copyWith(bottom: 12),
          child: pw.Column(children: [
            pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text("Page ${pageNo + 1} out of $totalPageCount")),
            pw.Center(child: pw.Text("[Building Name]", textAlign: pw.TextAlign.center, style: pw.TextStyle(color: PdfColors.blueAccent, fontSize: 25, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 6),
            pw.Center(child: pw.Text("[Building Address]", textAlign: pw.TextAlign.center)),
            pw.Divider(thickness: 1, height: 16, color: PdfColors.grey300),
            pw.Center(
                child: pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 4),
                    padding: const pw.EdgeInsets.all(6),
                    decoration: const pw.BoxDecoration(color: PdfColors.black),
                    child: pw.Text("[Document Title]", style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold)))),
            pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.only(top: 6), child: pdfElement))
          ])),
      pw.Expanded(child: pw.SizedBox()),
      pw.Image(pw.MemoryImage(imageData)),
      pw.Container(
          padding: const pw.EdgeInsets.only(top: 12),
          width: double.maxFinite,
          alignment: pw.Alignment.center,
          decoration: const pw.BoxDecoration(color: PdfColors.blueAccent),
          child: pw.Paragraph(text: "www.hisocietybd.com", textAlign: pw.TextAlign.center, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)))
    ];
  }
}

Expanded primaryDataTable({required String titleHeader, required String valueHeader, required List<DataRow> rows}) => Expanded(
    child: DataTable(
        columnSpacing: primaryPaddingValue / 4,
        horizontalMargin: primaryPaddingValue,
        dividerThickness: 1,
        headingRowHeight: 48,
        headingTextStyle: semiBold14Blue.copyWith(color: themeBlack),
        showBottomBorder: true,
        decoration: BoxDecoration(border: Border.symmetric(vertical: BorderSide(width: .5, color: themeGrey))),
        dataRowMaxHeight: 44,
        dataRowMinHeight: 44,
        columns: [DataColumn(label: Text(titleHeader)), DataColumn(numeric: true, label: Text(valueHeader))],
        rows: rows));

DataRow balanceSheetDataTile({String? title, String? amount, bool alternate = false, VoidCallback? onEditTap, required BuildContext context, Color? color}) => DataRow(selected: alternate, cells: [
      DataCell(SizedBox(width: (MediaQuery.of(context).size.width) / 4, child: Text(title ?? "", style: normal14Black.copyWith(fontSize: 12)))),
      DataCell(
          onTap: onEditTap,
          SizedBox(
              width: (MediaQuery.of(context).size.width) / 4 - primaryPaddingValue * 2,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text(amount.toString() == "null" ? "" : currencyDigit(num.parse(amount.toString())), style: semiBold16Black.copyWith(color: color ?? primaryColor, fontStyle: FontStyle.italic)),
                if (onEditTap.toString() != "null") Padding(padding: EdgeInsets.only(left: primaryPaddingValue / 6), child: Icon(Icons.edit, color: primaryColor, size: 13))
              ])))
    ]);

String webPdfCheck(String? string) {
  String newString = "";
  if (string != "null" && string != null) newString = string.replaceAll("়", "");
  newString = newString.toBijoyIf(!isEnglish(newString));
  return newString;
}

bool isEnglish(String? str) {
  if (str == null) return true;
  for (int i = 0; i < str.length; i++) {
    int charCode = str.codeUnitAt(i);
    if ((charCode < 65 || charCode > 90) && // A-Z
        (charCode < 97 || charCode > 122) && // a-z
        (charCode < 48 || charCode > 57) && // 0-9
        (charCode != 32) && // space
        (charCode < 33 || charCode > 47) && // basic punctuations
        (charCode < 58 || charCode > 64) && // more basic punctuations
        (charCode < 91 || charCode > 96) && // more basic punctuations
        (charCode < 123 || charCode > 126)) // more basic punctuations
    {
      return false;
    }
  }
  return true;
}
