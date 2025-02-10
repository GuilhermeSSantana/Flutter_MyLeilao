// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/product_list_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // Novo controller para nome
  final _cpfController = TextEditingController(); // Novo controller para CPF
  final _phoneController =
      TextEditingController(); // Novo controller para telefone

  bool isLogin = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose(); // Dispose novo controller
    _cpfController.dispose(); // Dispose novo controller
    _phoneController.dispose(); // Dispose novo controller
    super.dispose();
  }

  Future<void> _authenticate() async {
    try {
      if (isLogin) {
        // Login
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Registro
        // Primeiro, criar usuário no Firebase Authentication
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Depois, criar documento na collection de usuários no Firestore
        await _firestore
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .set({
          'nome': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'cpf': _cpfController.text.trim(),
          'telefone': _phoneController.text.trim(),
          'adm': false, // Campo fixo como solicitado
          'criadoEm': FieldValue
              .serverTimestamp(), // Timestamp opcional, mas recomendado
        });
      }

      // Redirecionar para a tela de leilões
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ProductListScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Erro na autenticação')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autenticação')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isLogin) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  controller: _cpfController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'CPF'),
                ),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
              ],
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _authenticate,
                child: Text(isLogin ? 'Entrar' : 'Registrar'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                  });
                },
                child: Text(isLogin
                    ? 'Não tem uma conta? Registre-se'
                    : 'Já tem uma conta? Faça login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
