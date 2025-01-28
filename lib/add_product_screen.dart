import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _imagemController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _valorController.dispose();
    _imagemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Produto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Informe o nome' : null,
              ),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Informe a descrição' : null,
              ),
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(labelText: 'Valor'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final trimmedValue = value!.trim();
                  if (trimmedValue.isEmpty) return 'Informe o valor';
                  if (double.tryParse(trimmedValue) == null)
                    return 'Informe um valor válido';
                  return null;
                },
              ),
              TextFormField(
                controller: _imagemController,
                decoration: const InputDecoration(labelText: 'URL da Imagem'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final productData = {
                      'nome': _nomeController.text.trim(),
                      'descricao': _descricaoController.text.trim(),
                      'valor': double.parse(_valorController.text.trim()),
                      'imagem': _imagemController.text.trim(),
                    };
                    await FirebaseFirestore.instance
                        .collection('products')
                        .add(productData);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Cadastrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
