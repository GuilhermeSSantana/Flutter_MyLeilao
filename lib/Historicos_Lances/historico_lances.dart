import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserBidsScreen extends StatefulWidget {
  const UserBidsScreen({super.key});

  @override
  _UserBidsScreenState createState() => _UserBidsScreenState();
}

class _UserBidsScreenState extends State<UserBidsScreen> {
  final _currencyFormatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  String? _currentUserId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
      debugPrint('ID do usuário atual: $_currentUserId');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meus Lances e Leilões'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Meus Lances'),
              Tab(text: 'Leilões Ativos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserBidsTab(),
            _buildActiveAuctionsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBidsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bids')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('bidTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Verifica se é erro de índice
          if (snapshot.error.toString().contains('failed-precondition')) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                      'Configurando banco de dados...\nPor favor, aguarde alguns minutos.'),
                ],
              ),
            );
          }
          return Center(
              child: Text('Erro ao carregar dados: ${snapshot.error}'));
        }
        // stream: _firestore
        //     .collection('bids')
        //     .where('userId', isEqualTo: _currentUserId)
        //     .orderBy('bidTime', descending: true)
        //     .snapshots(),
        // builder: (context, snapshot) {
        //   // Debug prints
        //   debugPrint('Status da conexão: ${snapshot.connectionState}');
        //   debugPrint('Tem dados? ${snapshot.hasData}');
        //   if (snapshot.hasData) {
        //     debugPrint('Número de documentos: ${snapshot.data!.docs.length}');
        //   }
        //   if (snapshot.hasError) {
        //     debugPrint('Erro: ${snapshot.error}');
        //     return Center(
        //         child: Text('Erro ao carregar dados: ${snapshot.error}'));
        //   }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Você ainda não deu lances'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var bidDoc = snapshot.data!.docs[index];
            var bidData = bidDoc.data() as Map<String, dynamic>;

            return FutureBuilder<DocumentSnapshot>(
              future: _firestore
                  .collection('products')
                  .doc(bidData['productId'])
                  .get(),
              builder: (context, productSnapshot) {
                if (productSnapshot.hasError) {
                  return ListTile(
                    title: Text(
                        'Erro ao carregar produto: ${productSnapshot.error}'),
                  );
                }

                if (!productSnapshot.hasData) {
                  return const ListTile(
                    title: Text('Carregando...'),
                    leading: CircularProgressIndicator(),
                  );
                }

                if (!productSnapshot.data!.exists) {
                  return ListTile(
                    title: Text(
                        'Produto não encontrado (ID: ${bidData['productId']})'),
                  );
                }

                var productData =
                    productSnapshot.data!.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(
                      productData['nome'] ?? 'Nome não disponível',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seu lance: ${_currencyFormatter.format(bidData['bidValue'] ?? 0)}',
                          style: const TextStyle(color: Colors.blue),
                        ),
                        Text(
                          'Lance atual: ${_currencyFormatter.format(productData['valor'] ?? 0)}',
                          style: const TextStyle(color: Colors.green),
                        ),
                        Text(
                          'Data do lance: ${DateFormat('dd/MM/yyyy HH:mm').format((bidData['bidTime'] as Timestamp).toDate())}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: bidData['bidValue'] == productData['valor']
                        ? const Icon(Icons.gavel, color: Colors.green)
                        : const Icon(Icons.gavel_outlined, color: Colors.grey),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildActiveAuctionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('products')
          .where('status', isEqualTo: 'ativo')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Erro ao carregar leilões: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhum leilão ativo'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var productDoc = snapshot.data!.docs[index];
            var productData = productDoc.data() as Map<String, dynamic>;
            var productId = productDoc.id;

            return FutureBuilder<QuerySnapshot>(
              future: _firestore
                  .collection('bids')
                  .where('userId', isEqualTo: _currentUserId)
                  .where('productId', isEqualTo: productId)
                  .orderBy('bidTime', descending: true)
                  .limit(1)
                  .get(),
              builder: (context, bidSnapshot) {
                bool hasUserBid =
                    bidSnapshot.hasData && bidSnapshot.data!.docs.isNotEmpty;
                var userBidValue = hasUserBid
                    ? (bidSnapshot.data!.docs.first.data()
                        as Map<String, dynamic>)['bidValue']
                    : null;

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(
                      productData['nome'] ?? 'Nome não disponível',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lance atual: ${_currencyFormatter.format(productData['valor'] ?? 0)}',
                          style: const TextStyle(color: Colors.green),
                        ),
                        if (hasUserBid)
                          Text(
                            'Seu último lance: ${_currencyFormatter.format(userBidValue ?? 0)}',
                            style: const TextStyle(color: Colors.blue),
                          ),
                        Text(
                          'Data de início: ${DateFormat('dd/MM/yyyy HH:mm').format((productData['dataInicio'] as Timestamp).toDate())}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: hasUserBid
                        ? const Icon(Icons.gavel, color: Colors.blue)
                        : const Icon(Icons.gavel_outlined, color: Colors.grey),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
