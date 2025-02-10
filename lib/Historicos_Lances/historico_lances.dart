import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserBidsScreen extends StatefulWidget {
  const UserBidsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UserBidsScreenState createState() => _UserBidsScreenState();
}

class _UserBidsScreenState extends State<UserBidsScreen> {
  final _currencyFormatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
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
      stream: FirebaseFirestore.instance
          .collection('bids')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('bidTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Você ainda não deu lances'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var bidData =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('products')
                  .doc(bidData['productId'])
                  .get(),
              builder: (context, productSnapshot) {
                if (!productSnapshot.hasData) {
                  return const ListTile(title: Text('Carregando...'));
                }

                var productData =
                    productSnapshot.data!.data() as Map<String, dynamic>;

                return ListTile(
                  title: Text(productData['nome']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seu lance: ${_currencyFormatter.format(bidData['bidValue'])}',
                        style: const TextStyle(color: Colors.blue),
                      ),
                      Text(
                        'Lance atual: ${_currencyFormatter.format(productData['valor'])}',
                        style: const TextStyle(color: Colors.green),
                      ),
                      Text(
                        'Data do lance: ${DateFormat('dd/MM/yyyy HH:mm').format(bidData['bidTime'].toDate())}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: bidData['bidValue'] == productData['valor']
                      ? const Icon(Icons.gavel, color: Colors.green)
                      : const Icon(Icons.gavel_outlined, color: Colors.grey),
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
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('status', isEqualTo: 'ativo')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhum leilão ativo'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var productData =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            var productId = snapshot.data!.docs[index].id;

            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('bids')
                  .where('userId', isEqualTo: _currentUserId)
                  .where('productId', isEqualTo: productId)
                  .limit(1)
                  .get(),
              builder: (context, bidSnapshot) {
                bool hasUserBid =
                    bidSnapshot.hasData && bidSnapshot.data!.docs.isNotEmpty;

                return ListTile(
                  title: Text(productData['nome']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lance atual: ${_currencyFormatter.format(productData['valor'])}',
                        style: const TextStyle(color: Colors.green),
                      ),
                      if (hasUserBid)
                        Text(
                          'Seu último lance: ${_currencyFormatter.format((bidSnapshot.data!.docs.first.data() as Map<String, dynamic>)['bidValue'])}',
                          style: const TextStyle(color: Colors.blue),
                        ),
                      Text(
                        'Data de início: ${DateFormat('dd/MM/yyyy HH:mm').format(productData['dataInicio'].toDate())}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: hasUserBid
                      ? const Icon(Icons.gavel, color: Colors.blue)
                      : const Icon(Icons.gavel_outlined, color: Colors.grey),
                );
              },
            );
          },
        );
      },
    );
  }
}
