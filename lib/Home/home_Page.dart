// ignore: file_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/Historicos_Lances/historico_lances.dart';
import 'package:my_app/Login/AuthScreen.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    if (_disposed) return; // Check if widget is disposed

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

        if (!_disposed && mounted) {
          // Double check both conditions
          setState(() {
            _isAdmin = userDoc.data()?['adm'] ?? false;
          });
        }
      } catch (e) {
        debugPrint('Error checking admin status: $e');
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      // Navegue para a tela de autenticação e remova todas as telas anteriores da pilha
      if (!_disposed && mounted) {
        // Check if widget is still mounted
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!_disposed && mounted) {
        // Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer logout: $e')),
        );
      }
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
          if (mounted) {
            // Check if widget is mounted before setState
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
