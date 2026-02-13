import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompleteProfilePage extends StatefulWidget {
  final VoidCallback onSaved;
  const CompleteProfilePage({super.key, required this.onSaved});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  String? selectedFaculty;
  String? selectedCourse;
  String? selectedGroup;
  bool isSaving = false;
  bool isInitialDataLoaded = false;

  final List<String> courses = ['1', '2', '3', '4', '1 (Маг)', '2 (Маг)'];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  // Завантажуємо існуючі дані профілю для редагування [cite: 140]
  Future<void> _loadCurrentUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          selectedFaculty = data['faculty'];
          selectedCourse = data['course']?.toString();
          selectedGroup = data['group'];
          isInitialDataLoaded = true;
        });
      } else {
        setState(() => isInitialDataLoaded = true);
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && selectedFaculty != null && selectedGroup != null) {
      setState(() => isSaving = true);
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'faculty': selectedFaculty,
          'course': selectedCourse,
          'group': selectedGroup,
          'isProfileComplete': true,
        }, SetOptions(merge: true));

        if (mounted) {
          // Показуємо успішне сповіщення 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Дані успішно оновлено!'),
              backgroundColor: Color(0xFF2D5A40),
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          widget.onSaved();
          Navigator.of(context).pop(); // Повертаємось назад після успіху
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialDataLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF2D5A40))));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2D5A40)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0F4F1), Color(0xFFD9E8DD)],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.5)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.manage_accounts_rounded, size: 60, color: Color(0xFF2D5A40)),
                          const SizedBox(height: 16),
                          const Text(
                            "Мій профіль",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40)),
                          ),
                          const SizedBox(height: 8),
                          const Text("Вкажіть дані для розкладу", style: TextStyle(color: Colors.black54)),
                          const SizedBox(height: 32),
                          _buildGlassDropdown("Факультет", _facultyItems()),
                          const SizedBox(height: 20),
                          _buildGlassDropdown("Курс", _courseItems()),
                          const SizedBox(height: 20),
                          _buildGroupSection(),
                          const SizedBox(height: 40),
                          _buildSaveButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassDropdown(String label, Widget dropdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(label, style: const TextStyle(color: Color(0xFF2D5A40), fontWeight: FontWeight.w600)),
        ),
        dropdown,
      ],
    );
  }

  Widget _facultyItems() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('university_structure').snapshots(),
      builder: (context, snapshot) {
        return _styledDropdown(
          value: selectedFaculty,
          hint: "Оберіть факультет",
          items: snapshot.hasData 
              ? snapshot.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.id))).toList()
              : [],
          onChanged: (val) => setState(() { selectedFaculty = val; selectedGroup = null; }),
        );
      },
    );
  }

  Widget _courseItems() {
    return _styledDropdown(
      value: selectedCourse,
      hint: "Оберіть курс",
      items: courses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (val) => setState(() { selectedCourse = val; selectedGroup = null; }),
    );
  }

  Widget _buildGroupSection() {
    if (selectedFaculty == null || selectedCourse == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8),
          child: Text("Група", style: TextStyle(color: Color(0xFF2D5A40), fontWeight: FontWeight.w600)),
        ),
        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('university_structure').doc(selectedFaculty).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            
            List<dynamic> allGroups = snapshot.data!['groups'] ?? [];
            String courseDigit = selectedCourse!.split(' ')[0];
            List<String> filteredGroups = allGroups
                .map((e) => e.toString())
                .where((g) => g.contains('-$courseDigit'))
                .toList();

            return _styledDropdown(
              value: selectedGroup,
              hint: "Оберіть групу",
              items: filteredGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => setState(() => selectedGroup = val),
            );
          },
        ),
      ],
    );
  }

  Widget _styledDropdown({required String? value, required String hint, required List<DropdownMenuItem<String>> items, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.black38)),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2D5A40)),
          items: items,
          onChanged: onChanged,
          dropdownColor: const Color(0xFFF0F4F1),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return isSaving 
      ? const CircularProgressIndicator(color: Color(0xFF2D5A40))
      : GestureDetector(
          onTap: (selectedGroup != null) ? _saveProfile : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: (selectedGroup != null) ? const Color(0xFF2D5A40) : Colors.grey,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Text(
                "ЗБЕРЕГТИ ЗМІНИ",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
          ),
        );
  }
}