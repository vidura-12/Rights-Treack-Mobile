class ReportCaseScreen extends StatefulWidget {
  @override
  _ReportCaseScreenState createState() => _ReportCaseScreenState();
}

class _ReportCaseScreenState extends State<ReportCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  String? victimGender, abuserGender;
  DateTime? fromDate, toDate;
  List<XFile> mediaFiles = [];

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final locationCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Report a Case")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: titleCtrl, decoration: InputDecoration(labelText: "Case Title")),
              TextFormField(controller: descCtrl, decoration: InputDecoration(labelText: "Description")),
              TextFormField(controller: locationCtrl, decoration: InputDecoration(labelText: "Location")),

              DropdownButtonFormField<String>(
                value: victimGender,
                hint: Text("Victim Gender"),
                items: ["Male", "Female", "Other"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => victimGender = val),
              ),
              DropdownButtonFormField<String>(
                value: abuserGender,
                hint: Text("Abuser Gender"),
                items: ["Male", "Female", "Other"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => abuserGender = val),
              ),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      child: Text(fromDate == null ? "Select From Date" : fromDate!.toLocal().toString().split(" ")[0]),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => fromDate = picked);
                      },
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      child: Text(toDate == null ? "Select To Date" : toDate!.toLocal().toString().split(" ")[0]),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => toDate = picked);
                      },
                    ),
                  ),
                ],
              ),

              ElevatedButton(
                onPressed: () async {
                  // TODO: Upload logic
                },
                child: Text("Upload Media"),
              ),

              SizedBox(height: 20),
              ElevatedButton(
                child: Text("Submit Case"),
                onPressed: () => _submitCase(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitCase() async {
    if (!_formKey.currentState!.validate()) return;

    // Upload media to Firebase Storage
    List<String> uploadedUrls = [];
    for (var file in mediaFiles) {
      final ref = FirebaseStorage.instance.ref().child("cases/${DateTime.now().millisecondsSinceEpoch}_${file.name}");
      await ref.putFile(File(file.path));
      uploadedUrls.add(await ref.getDownloadURL());
    }

    await FirebaseFirestore.instance.collection("cases").add({
      "title": titleCtrl.text,
      "description": descCtrl.text,
      "location": locationCtrl.text,
      "victimGender": victimGender,
      "abuserGender": abuserGender,
      "fromDate": fromDate,
      "toDate": toDate,
      "status": "Investigation",
      "createdBy": FirebaseAuth.instance.currentUser!.uid,
      "createdAt": Timestamp.now(),
      "mediaUrls": uploadedUrls,
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Case Reported Successfully")));
    Navigator.pop(context);
  }
}
