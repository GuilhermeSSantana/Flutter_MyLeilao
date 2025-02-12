// ignore: file_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/Historicos_Lances/historico_lances.dart';
import 'package:my_app/add_product_screen.dart';
import 'package:my_app/product_list_screen.dart';
import 'package:my_app/auth_screen.dart'; // Adicione este import

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      // Navegue para a tela de autenticação e remova todas as telas anteriores da pilha
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer logout: $e')),
      );
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
      appBar: AppBar(
        title: const Text('Leilões'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
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