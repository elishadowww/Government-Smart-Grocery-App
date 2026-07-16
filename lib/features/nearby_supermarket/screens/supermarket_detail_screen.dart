import 'package:flutter/material.dart';
import '../models/supermarket_model.dart';

class SupermarketDetailScreen extends StatelessWidget {
  final SupermarketModel supermarket;

  const SupermarketDetailScreen({
    super.key,
    required this.supermarket,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(supermarket.name),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Store Icon
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: Colors.green,
                    size: 60,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  supermarket.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),

                  const SizedBox(width: 5),

                  Text(
                    supermarket.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(width: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: supermarket.isOpen
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      supermarket.isOpen
                          ? "Open"
                          : "Closed",
                      style: TextStyle(
                        color: supermarket.isOpen
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "Address",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Icon(
                    Icons.location_on,
                    color: Colors.red,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      supermarket.address,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              const Divider(),

              const SizedBox(height: 10),

              const Text(
                "Products",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              _comingSoonCard(
                icon: Icons.shopping_bag,
                title: "Product Catalogue",
                subtitle:
                "Products available in this supermarket will appear here.",
              ),

              const SizedBox(height: 20),

              const Text(
                "Promotions",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              _comingSoonCard(
                icon: Icons.local_offer,
                title: "Latest Promotions",
                subtitle:
                "Current supermarket promotions will appear here.",
              ),

              const SizedBox(height: 20),

              const Text(
                "Price Comparison",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              _comingSoonCard(
                icon: Icons.compare_arrows,
                title: "Compare Prices",
                subtitle:
                "Compare product prices with other supermarkets.",
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _comingSoonCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade50,
          child: Icon(
            icon,
            color: Colors.green,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Chip(
          label: Text("Coming Soon"),
        ),
      ),
    );
  }
}