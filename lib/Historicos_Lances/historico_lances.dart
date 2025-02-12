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
              Tab(text: 'Meus Leilões'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserBidsTab(),
            _buildUserAuctionsTab(),
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
                          'Erro ao carregar produto: ${productSnapshot.error}'));
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
                          'Produto não encontrado (ID: ${bidData['productId']})'));
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
                        Text(
                          'Status: ${productData['status'] ?? 'Não disponível'}',
                          style: TextStyle(
                            color: _getStatusColor(productData['status']),
                            fontWeight: FontWeight.bold,
                          ),
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

  // Widget _buildUserAuctionsTab() {
  //   return StreamBuilder<QuerySnapshot>(
  //     stream: _firestore
  //         .collection('bids')
  //         .where('userId', isEqualTo: _currentUserId)
  //         .orderBy('bidTime', descending: true)
  //         .snapshots(),
  //     builder: (context, bidsSnapshot) {
  //       if (bidsSnapshot.hasError) {
  //         return Center(
  //             child: Text('Erro ao carregar leilões: ${bidsSnapshot.error}'));
  //       }

  //       if (bidsSnapshot.connectionState == ConnectionState.waiting) {
  //         return const Center(child: CircularProgressIndicator());
  //       }

  //       if (!bidsSnapshot.hasData || bidsSnapshot.data!.docs.isEmpty) {
  //         return const Center(
  //             child: Text('Você não participou de nenhum leilão'));
  //       }

  //       // Get unique product IDs from bids
  //       Set<String> productIds = bidsSnapshot.data!.docs
  //           .map((doc) =>
  //               (doc.data() as Map<String, dynamic>)['productId'] as String)
  //           .toSet();

  //       return StreamBuilder<QuerySnapshot>(
  //         stream: _firestore
  //             .collection('products')
  //             .where(FieldPath.documentId, whereIn: productIds.toList())
  //             .snapshots(),
  //         builder: (context, productsSnapshot) {
  //           if (productsSnapshot.hasError) {
  //             return Center(
  //                 child: Text(
  //                     'Erro ao carregar produtos: ${productsSnapshot.error}'));
  //           }

  //           if (productsSnapshot.connectionState == ConnectionState.waiting) {
  //             return const Center(child: CircularProgressIndicator());
  //           }

  //           if (!productsSnapshot.hasData ||
  //               productsSnapshot.data!.docs.isEmpty) {
  //             return const Center(child: Text('Nenhum leilão encontrado'));
  //           }

  //           return ListView.builder(
  //             itemCount: productsSnapshot.data!.docs.length,
  //             itemBuilder: (context, index) {
  //               var productDoc = productsSnapshot.data!.docs[index];
  //               var productData = productDoc.data() as Map<String, dynamic>;
  //               var userBids = bidsSnapshot.data!.docs
  //                   .where((bid) => bid['productId'] == productDoc.id)
  //                   .toList();
  //               var highestUserBid = userBids.reduce((curr, next) =>
  //                   (curr['bidValue'] as num) > (next['bidValue'] as num)
  //                       ? curr
  //                       : next);

  //               return Card(
  //                 margin: const EdgeInsets.all(8.0),
  //                 child: ListTile(
  //                   title: Text(
  //                     productData['nome'] ?? 'Nome não disponível',
  //                     style: const TextStyle(fontWeight: FontWeight.bold),
  //                   ),
  //                   subtitle: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         'Lance atual: ${_currencyFormatter.format(productData['valor'] ?? 0)}',
  //                         style: const TextStyle(color: Colors.green),
  //                       ),
  //                       Text(
  //                         'Seu maior lance: ${_currencyFormatter.format(highestUserBid['bidValue'] ?? 0)}',
  //                         style: const TextStyle(color: Colors.blue),
  //                       ),
  //                       Text(
  //                         'Status: ${productData['status'] ?? 'Não disponível'}',
  //                         style: TextStyle(
  //                           color: _getStatusColor(productData['status']),
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                       Text(
  //                         'Total de lances: ${userBids.length}',
  //                         style: const TextStyle(color: Colors.grey),
  //                       ),
  //                     ],
  //                   ),
  //                   trailing: highestUserBid['bidValue'] == productData['valor']
  //                       ? const Icon(Icons.gavel, color: Colors.green)
  //                       : const Icon(Icons.gavel_outlined, color: Colors.grey),
  //                 ),
  //               );
  //             },
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  Widget _buildUserAuctionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bids')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('bidTime', descending: true)
          .snapshots(),
      builder: (context, bidsSnapshot) {
        if (bidsSnapshot.hasError) {
          return Center(
              child: Text('Erro ao carregar leilões: ${bidsSnapshot.error}'));
        }

        if (bidsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!bidsSnapshot.hasData || bidsSnapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('Você não participou de nenhum leilão'));
        }

        // Get unique product IDs from bids
        Set<String> productIds = bidsSnapshot.data!.docs
            .map((doc) =>
                (doc.data() as Map<String, dynamic>)['productId'] as String)
            .toSet();

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('products')
              .where(FieldPath.documentId, whereIn: productIds.toList())
              .snapshots(),
          builder: (context, productsSnapshot) {
            if (productsSnapshot.hasError) {
              return Center(
                  child: Text(
                      'Erro ao carregar produtos: ${productsSnapshot.error}'));
            }

            if (productsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!productsSnapshot.hasData ||
                productsSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Nenhum leilão encontrado'));
            }

            return ListView.builder(
              itemCount: productsSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var productDoc = productsSnapshot.data!.docs[index];
                var productData = productDoc.data() as Map<String, dynamic>;

                // Get all bids for this product
                var userBids = bidsSnapshot.data!.docs
                    .where((bid) =>
                        (bid.data() as Map<String, dynamic>)['productId'] ==
                        productDoc.id)
                    .toList();

                // Find highest bid safely
                double highestUserBidValue = 0;
                if (userBids.isNotEmpty) {
                  highestUserBidValue = userBids.map((bid) {
                    final bidData = bid.data() as Map<String, dynamic>;
                    return (bidData['bidValue'] as num).toDouble();
                  }).reduce((max, value) => value > max ? value : max);
                }

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
                        Text(
                          'Seu maior lance: ${_currencyFormatter.format(highestUserBidValue)}',
                          style: const TextStyle(color: Colors.blue),
                        ),
                        Text(
                          'Status: ${productData['status'] ?? 'Não disponível'}',
                          style: TextStyle(
                            color: _getStatusColor(productData['status']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total de lances: ${userBids.length}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: (highestUserBidValue ==
                            (productData['valor'] as num).toDouble())
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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'ativo':
        return Colors.green;
      case 'finalizado':
        return Colors.red;
      case 'pendente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
