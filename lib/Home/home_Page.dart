// ignore: file_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/Historicos_Lances/historico_lances.dart';
import 'package:my_app/add_product_screen.dart';
import 'package:my_app/product_list_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      setState(() {
        _isAdmin = userDoc.data()?['adm'] ?? false;
      });
    }
  }

  List<BottomNavigationBarItem> _getNavBarItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: 'Histórico de Lances',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.gavel),
        label: 'Leilões',
      ),
      if (_isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.add_circle),
          label: 'Adicionar Produto',
        ),
    ];
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return const ProductListScreen();
      case 1:
        return const UserBidsScreen();
      case 2:
        return const UserBidsScreen();
      case 3:
        return _isAdmin ? const AddProductScreen() : const ProductListScreen();
      default:
        return const ProductListScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getSelectedScreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: _getNavBarItems(),
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
