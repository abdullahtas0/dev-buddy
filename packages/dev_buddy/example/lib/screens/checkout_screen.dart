import 'dart:io';
import 'package:flutter/material.dart';
import '../models/cart_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _loading = false;
  bool _success = false;

  Future<void> _placeOrder() async {
    setState(() => _loading = true);

    // Simulated slow API call — 3 seconds.
    // DevBuddy NetworkModule will flag this as "Slow Request: 3000ms".
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('https://httpbin.org/delay/3'),
      );
      final response = await request.close();
      await response.drain<void>();
      client.close();
    } catch (_) {
      // Network call may fail — that's OK for demo
    }

    if (!mounted) return;
    CartModel.instance.clear();
    setState(() {
      _loading = false;
      _success = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Placed')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 80, color: Colors.green.shade400),
              const SizedBox(height: 16),
              const Text('Order Placed Successfully!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Thank you for your purchase.',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      );
    }

    final cart = CartModel.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...cart.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text('${item.product.name} x${item.quantity}')),
                      Text('\$${item.total.toStringAsFixed(2)}'),
                    ],
                  ),
                )),
            const Divider(height: 24),
            Row(
              children: [
                const Text('Total',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('\$${cart.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _loading ? null : _placeOrder,
                child: _loading
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Place Order', style: TextStyle(fontSize: 16)),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Processing payment... (this takes ~3 seconds)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
