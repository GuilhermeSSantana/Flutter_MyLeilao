import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatação de moeda

import 'add_product_screen.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  String formatCurrency(double value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos em Leilão'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddProductScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar os dados.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum produto cadastrado.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final valor = data['valor'] is double
                  ? data['valor']
                  : (data['valor'] as num).toDouble();
              return ListTile(
                title: Text(data['nome']),
                subtitle: Text(formatCurrency(valor)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              ProductDetailsDialog(data: data),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.gavel),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              BidDialog(productId: doc.id, currentBid: valor),
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class ProductDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProductDetailsDialog({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(data['nome']),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((entry) {
          final value = entry.key == 'valor'
              ? NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                  .format(entry.value)
              : entry.value.toString();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text('${entry.key}: $value'),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class BidDialog extends StatefulWidget {
  final String productId;
  final double currentBid;

  const BidDialog(
      {required this.productId, required this.currentBid, super.key});

  @override
  State<BidDialog> createState() => _BidDialogState();
}

class _BidDialogState extends State<BidDialog> {
  final _bidController = TextEditingController();

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dar um Lance'),
      content: TextField(
        controller: _bidController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Valor do Lance'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final bidValue = double.tryParse(_bidController.text);
            if (bidValue != null && bidValue >= widget.currentBid) {
              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(widget.productId)
                  .update({'valor': bidValue});
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('O lance deve ser maior ou igual ao valor atual.'),
                ),
              );
            }
          },
          child: const Text('Dar Lance'),
        ),
      ],
    );
  }
}
