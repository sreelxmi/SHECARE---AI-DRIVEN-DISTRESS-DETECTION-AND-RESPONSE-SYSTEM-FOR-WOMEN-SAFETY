import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ViewProfilePage extends StatefulWidget {
  const ViewProfilePage({super.key});

  @override
  State<ViewProfilePage> createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage> {
  Map profile = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      String url = "$baseUrl/myapp/pinkpolice_view_profile/";

      var response = await http.post(
          Uri.parse(url),
          body: {"lid": lid.toString()}
      );
      print(response.body);

      var jsonData = json.decode(response.body);

      if (jsonData["status"] == "ok") {
        setState(() {
          profile = jsonData["data"];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? _buildLoadingState()
          : profile.isEmpty
          ? _buildEmptyState()
          : _buildProfileContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.pink[300]!),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Loading profile...",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            "Profile Not Available",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Unable to load profile information",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return RefreshIndicator(
      onRefresh: fetchProfile,
      color: const Color(0xFFE91E63),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Profile Image
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.pink.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: profile["photo"] != null && profile["photo"].isNotEmpty
                            ? Image.network(
                          profile["photo"],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 1,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.grey[300]!,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[100],
                              child: Icon(
                                Icons.person_outline,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        )
                            : Icon(
                          Icons.person_outline,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name and Badge
                    Text(
                      profile["officername"] ?? "Officer",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),

                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            size: 12,
                            color: Colors.pink,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Pink Police Officer",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.pink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Personal Information Section
            _buildSectionCard(
              title: "Personal Information",
              icon: Icons.person_outline,
              color: Colors.blue,
              children: [
                _buildInfoRow(
                  icon: Icons.directions_car_outlined,
                  label: "Vehicle Number",
                  value: profile["vechileno"]?.toString() ?? "Not provided",
                ),
                _buildInfoRow(
                  icon: Icons.transgender_outlined,
                  label: "Gender",
                  value: profile["gender"] ?? "Not provided",
                ),
                _buildInfoRow(
                  icon: Icons.email_outlined,
                  label: "Email",
                  value: profile["email"] ?? "Not provided",
                ),
                _buildInfoRow(
                  icon: Icons.phone_outlined,
                  label: "Phone",
                  value: profile["phone"]?.toString() ?? "Not provided",
                ),
                _buildInfoRow(
                  icon: Icons.cake_outlined,
                  label: "Date of Birth",
                  value: profile["dob"]?.toString() ?? "Not provided",
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location Information Section
            _buildSectionCard(
              title: "Location Details",
              icon: Icons.location_on_outlined,
              color: Colors.green,
              children: [
                _buildInfoRow(
                  icon: Icons.place_outlined,
                  label: "Place",
                  value: profile["place"] ?? "Not provided",
                ),
                _buildInfoRow(
                  icon: Icons.work_outline,
                  label: "Post",
                  value: profile["post"]?.toString() ?? "Not provided",
                ),
                _buildInfoRow(
                  icon: Icons.map_outlined,
                  label: "District",
                  value: profile["district"] ?? "Not provided",
                ),
                _buildInfoRow(
                  icon: Icons.public_outlined,
                  label: "State",
                  value: profile["state"] ?? "Not provided",
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Police Station Information Section
            _buildSectionCard(
              title: "Police Station",
              icon: Icons.security_outlined,
              color: Colors.orange,
              children: [
                _buildInfoRow(
                  icon: Icons.account_balance_outlined,
                  label: "Police Station",
                  value: profile["policestation"] ?? "Not provided",
                ),
                _buildInfoRow(
                  icon: Icons.location_city_outlined,
                  label: "PS Place",
                  value: profile["ps_place"] ?? "Not provided",
                ),
                _buildInfoRow(
                  icon: Icons.phone_android_outlined,
                  label: "PS Phone",
                  value: profile["ps_phone"]?.toString() ?? "Not provided",
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Divider
            Divider(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 12),

            // Info Rows
            Column(
              children: children,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}