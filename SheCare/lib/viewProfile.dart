import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserViewProfilePage extends StatefulWidget {
  const UserViewProfilePage({super.key});

  @override
  State<UserViewProfilePage> createState() => _UserViewProfilePageState();
}

class _UserViewProfilePageState extends State<UserViewProfilePage> {
  Map profile = {};
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUpdatingPhoto = false;
  String _errorMessage = "";
  String url = "";

  // Controllers for editing
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController placeCtrl = TextEditingController();
  final TextEditingController postCtrl = TextEditingController();
  final TextEditingController districtCtrl = TextEditingController();
  final TextEditingController stateCtrl = TextEditingController();
  final TextEditingController genderCtrl = TextEditingController();
  final TextEditingController idMarkCtrl = TextEditingController();
  final TextEditingController fatherCtrl = TextEditingController();
  final TextEditingController motherCtrl = TextEditingController();
  final TextEditingController bloodCtrl = TextEditingController();

  File? newPhotoFile;
  String? _genderValue;
  String? _bloodGroupValue;

  final List<String> genderOptions = ["Male", "Female", "Other"];
  final List<String> bloodGroups = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"];

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phCtrl.dispose();
    emailCtrl.dispose();
    placeCtrl.dispose();
    postCtrl.dispose();
    districtCtrl.dispose();
    stateCtrl.dispose();
    genderCtrl.dispose();
    idMarkCtrl.dispose();
    fatherCtrl.dispose();
    motherCtrl.dispose();
    bloodCtrl.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 800,
    );

    if (picked != null) {
      setState(() => newPhotoFile = File(picked.path));
    }
  }

  Future<void> updateProfilePhoto() async {
    if (newPhotoFile == null) return;

    setState(() {
      _isUpdatingPhoto = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      if (baseUrl.isEmpty || lid.isEmpty) {
        throw Exception("Server configuration missing");
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/myapp/update_profile_photo/"),
      );

      request.fields['lid'] = lid;

      request.files.add(await http.MultipartFile.fromPath(
        'photo',
        newPhotoFile!.path,
      ));

      var response = await request.send();
      var resp = await response.stream.bytesToString();
      var jsonData = json.decode(resp);

      if (jsonData["status"] != "ok") {
        throw Exception(jsonData["message"] ?? "Failed to update photo");
      }

      showSnackBar("Profile photo updated successfully!", isError: false);
    } catch (e) {
      showSnackBar("Failed to update photo: $e");
    } finally {
      setState(() {
        _isUpdatingPhoto = false;
      });
    }
  }

  Future<void> saveProfile() async {
    // Validation
    if (nameCtrl.text.isEmpty) {
      showSnackBar("Please enter your name");
      return;
    }
    if (phCtrl.text.isEmpty) {
      showSnackBar("Please enter your phone number");
      return;
    }
    if (emailCtrl.text.isNotEmpty && !emailCtrl.text.contains('@')) {
      showSnackBar("Please enter a valid email");
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = "";
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      if (baseUrl.isEmpty || lid.isEmpty) {
        throw Exception("Server configuration missing");
      }

      var response = await http.post(
        Uri.parse("$baseUrl/myapp/update_profile/"),
        body: {
          "lid": lid,
          "name": nameCtrl.text,
          "gender": genderCtrl.text,
          "phone": phCtrl.text,
          "email": emailCtrl.text,
          "place": placeCtrl.text,
          "post": postCtrl.text,
          "district": districtCtrl.text,
          "state": stateCtrl.text,
          "identificationmark": idMarkCtrl.text,
          "fathersname": fatherCtrl.text,
          "mothername": motherCtrl.text,
          "bloodgroup": bloodCtrl.text,
        },
      );

      var jsonData = json.decode(response.body);

      if (jsonData["status"] == "ok") {
        if (newPhotoFile != null) {
          await updateProfilePhoto();
        }

        showSnackBar("Profile updated successfully!", isError: false);

        setState(() {
          _isEditing = false;
        });

        await fetchProfile();
      } else {
        throw Exception(jsonData["message"] ?? "Failed to update profile");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: $e";
      });
      showSnackBar("Failed to update profile: $e");
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      if (baseUrl.isEmpty || lid.isEmpty) {
        throw Exception("Server configuration missing");
      }

      var response = await http.post(
        Uri.parse("$baseUrl/myapp/view_profile/"),
        body: {"lid": lid},
      );

      var jsonData = json.decode(response.body);

      if (jsonData["status"] == "ok") {
        profile = jsonData["data"];
        url = baseUrl;

        // Fill controllers
        nameCtrl.text = profile["name"] ?? "";
        genderCtrl.text = profile["gender"] ?? "";
        _genderValue = profile["gender"];
        phCtrl.text = profile["phone"]?.toString() ?? "";
        emailCtrl.text = profile["email"] ?? "";
        placeCtrl.text = profile["place"] ?? "";
        postCtrl.text = profile["post"] ?? "";
        districtCtrl.text = profile["district"] ?? "";
        stateCtrl.text = profile["state"] ?? "";
        idMarkCtrl.text = profile["identificationmark"] ?? "";
        fatherCtrl.text = profile["fathersname"] ?? "";
        motherCtrl.text = profile["mothername"] ?? "";
        bloodCtrl.text = profile["bloodgroup"] ?? "";
        _bloodGroupValue = profile["bloodgroup"];
      } else {
        throw Exception(jsonData["message"] ?? "Failed to load profile");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error loading profile: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Color(0xFFE91E63),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : "Not provided",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller,
      {bool isRequired = false, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF880E4F),
                ),
              ),
              if (isRequired)
                Text(
                  " *",
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink[50]!,
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              enabled: _isEditing,
              keyboardType: keyboardType,
              style: TextStyle(
                color: _isEditing ? Colors.grey[800] : Colors.grey[700],
                fontSize: 14,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: _isEditing ? Colors.white : Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.pink[200]!, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.pink[200]!, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFE91E63), width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> options,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF880E4F),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink[50]!,
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              items: options.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(
                    option,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _isEditing ? onChanged : null,
              decoration: InputDecoration(
                filled: true,
                fillColor: _isEditing ? Colors.white : Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.pink[200]!, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.pink[200]!, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFE91E63), width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                prefixIcon: Icon(
                  label.contains("Gender")
                      ? Icons.person_outline
                      : Icons.bloodtype_outlined,
                  size: 22,
                  color: Color(0xFFE91E63),
                ),
              ),
              icon: Icon(
                Icons.arrow_drop_down_outlined,
                color: Color(0xFFE91E63),
              ),
              dropdownColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? "Edit Profile" : "My Profile",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFE91E63),
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: "Edit Profile",
            ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: fetchProfile,
            tooltip: "Refresh",
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
            ),
            const SizedBox(height: 16),
            Text(
              "Loading profile...",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: fetchProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE91E63),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_outlined),
              label: const Text("Try Again"),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Header with Photo
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.pink[100]!, width: 1),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color(0xFFE91E63),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink[200]!.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _isUpdatingPhoto
                            ? Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
                          ),
                        )
                            : newPhotoFile != null
                            ? Image.file(
                          newPhotoFile!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                            : profile["photo"] != null &&
                            profile["photo"].isNotEmpty
                            ? Image.network(
                          "$url${profile["photo"]}",
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) {
                            return Container(
                              color: Colors.pink[100],
                              child: Icon(
                                Icons.person_outline,
                                size: 50,
                                color: Color(0xFFE91E63),
                              ),
                            );
                          },
                          loadingBuilder: (context, child,
                              loadingProgress) {
                            if (loadingProgress == null)
                              return child;
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                AlwaysStoppedAnimation<Color>(
                                    Color(0xFFE91E63)),
                              ),
                            );
                          },
                        )
                            : Container(
                          color: Colors.pink[100],
                          child: Icon(
                            Icons.person_outline,
                            size: 50,
                            color: Color(0xFFE91E63),
                          ),
                        ),
                      ),
                    ),
                    if (_isEditing)
                      GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Color(0xFFE91E63)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 20,
                            color: Color(0xFFE91E63),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  nameCtrl.text.isNotEmpty ? nameCtrl.text : "No Name",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF880E4F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  emailCtrl.text.isNotEmpty ? emailCtrl.text : "No Email",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      phCtrl.text.isNotEmpty ? phCtrl.text : "No Phone",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Profile Form
          if (_isEditing) ...[
            // Personal Information
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.pink[100]!, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Personal Information",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF880E4F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildEditableField("Full Name", nameCtrl, isRequired: true),
                    _buildEditableField("Phone Number", phCtrl,
                        isRequired: true, keyboardType: TextInputType.phone),
                    _buildEditableField("Email", emailCtrl,
                        keyboardType: TextInputType.emailAddress),
                    _buildDropdownField(
                      "Gender",
                      _genderValue,
                      genderOptions,
                          (value) {
                        setState(() {
                          _genderValue = value;
                          genderCtrl.text = value ?? "";
                        });
                      },
                    ),
                    _buildDropdownField(
                      "Blood Group",
                      _bloodGroupValue,
                      bloodGroups,
                          (value) {
                        setState(() {
                          _bloodGroupValue = value;
                          bloodCtrl.text = value ?? "";
                        });
                      },
                    ),
                    _buildEditableField(
                        "Identification Mark", idMarkCtrl),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Family Information
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.pink[100]!, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Family Information",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF880E4F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildEditableField("Father's Name", fatherCtrl),
                    _buildEditableField("Mother's Name", motherCtrl),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Address Information
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.pink[100]!, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Address Information",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF880E4F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildEditableField("Place", placeCtrl),
                    _buildEditableField("Post Office", postCtrl),
                    _buildEditableField("District", districtCtrl),
                    _buildEditableField("State", stateCtrl),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text("Save Changes"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () => setState(() {
                      _isEditing = false;
                      newPhotoFile = null;
                      fetchProfile();
                    }),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ] else ...[
            // View Mode
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Information Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.pink[100]!, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: Color(0xFFE91E63),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Personal Information",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF880E4F),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow("Gender", genderCtrl.text),
                        _buildInfoRow("Blood Group", bloodCtrl.text),
                        _buildInfoRow(
                            "Identification Mark", idMarkCtrl.text),
                        _buildInfoRow("Father's Name", fatherCtrl.text),
                        _buildInfoRow("Mother's Name", motherCtrl.text),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Address Information Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.pink[100]!, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFFE91E63),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Address Information",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF880E4F),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow("Place", placeCtrl.text),
                        _buildInfoRow("Post Office", postCtrl.text),
                        _buildInfoRow("District", districtCtrl.text),
                        _buildInfoRow("State", stateCtrl.text),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}