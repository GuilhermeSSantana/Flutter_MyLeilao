import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_app/Historicos_Lances/bid_history_dialog.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  // ignore: unused_field
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

  String formatCurrency(double value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  // Novo método para mostrar histórico
  void _showBidHistory(String productId) {
    showDialog(
      context: context,
      builder: (context) => BidHistoryDialog(productId: productId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos em Leilão'),
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
                      icon: const Icon(Icons.history),
                      onPressed: () => _showBidHistory(doc.id),
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
  final _currencyFormatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _bidController.addListener(_formatCurrency);
  }

  void _formatCurrency() {
    String text = _bidController.text.replaceAll(RegExp(r'[^\d]'), '');

    if (text.isNotEmpty) {
      // Converte para centavos
      double value = double.parse(text) / 100;

      // Formata como moeda
      final formattedValue = _currencyFormatter.format(value);

      _bidController.value = TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: formattedValue.length),
      );
    }
  }

  double _parseValue() {
    // Remove todos os caracteres que não são números
    String cleanText = _bidController.text.replaceAll(RegExp(r'[^\d]'), '');

    // Converte para double dividindo por 100 para obter o valor real
    return cleanText.isEmpty ? 0 : double.parse(cleanText) / 100;
  }

  @override
  void dispose() {
    _bidController.removeListener(_formatCurrency);
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
        decoration: const InputDecoration(
          labelText: 'Valor do Lance',
          hintText: 'R\$ 0,00',
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final bidValue = _parseValue();
            if (bidValue > 0 && bidValue >= widget.currentBid) {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                // Criar o lance no histórico
                await FirebaseFirestore.instance.collection('bids').add({
                  'userId': user.uid,
                  'productId': widget.productId,
                  'bidValue': bidValue,
                  'bidTime': FieldValue.serverTimestamp(),
                });

                // Atualizar o valor do produto
                await FirebaseFirestore.instance
                    .collection('products')
                    .doc(widget.productId)
                    .update({'valor': bidValue});

                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              }
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
