import 'package:flutter/material.dart';

class DummyData {
  static final List<Map<String, dynamic>> products = List.from([
    // Coffee
    {'id': 'COF_1', 'name': 'Caramel Macchiato', 'category': 'Coffee', 'price': 850, 'imageUrl': 'https://images.unsplash.com/photo-1485808191679-5f86510681a2?q=80&w=500', 'color': Colors.brown, 'icon': Icons.coffee},
    {'id': 'COF_2', 'name': 'Iced Latte', 'category': 'Coffee', 'price': 620, 'imageUrl': 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?q=80&w=500', 'color': Colors.blueGrey, 'icon': Icons.local_drink},
    {'id': 'COF_3', 'name': 'Espresso Shot', 'category': 'Coffee', 'price': 350, 'imageUrl': 'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?q=80&w=500', 'color': Colors.black87, 'icon': Icons.coffee_maker},
    {'id': 'COF_4', 'name': 'Cappuccino', 'category': 'Coffee', 'price': 580, 'imageUrl': 'https://images.unsplash.com/photo-1534778101976-62847782c213?q=80&w=500', 'color': Colors.brown, 'icon': Icons.coffee},
    {'id': 'COF_5', 'name': 'Cold Brew Coffee', 'category': 'Coffee', 'price': 720, 'imageUrl': 'https://images.unsplash.com/photo-1559496417-e7f25cb247f3?q=80&w=500', 'color': Colors.blueGrey, 'icon': Icons.local_drink},
    
    // Food
    {'id': 'FOD_1', 'name': 'Club Sandwich', 'category': 'Food', 'price': 1150, 'imageUrl': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?q=80&w=500', 'color': Colors.green, 'icon': Icons.fastfood},
    {'id': 'FOD_2', 'name': 'Beef Burger', 'category': 'Food', 'price': 1480, 'imageUrl': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=500', 'color': Colors.orange, 'icon': Icons.lunch_dining},
    {'id': 'FOD_3', 'name': 'Grilled Chicken', 'category': 'Food', 'price': 1690, 'imageUrl': 'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?q=80&w=500', 'color': Colors.brown, 'icon': Icons.restaurant},
    
    // Drinks
    {'id': 'DRK_1', 'name': 'Mango Smoothie', 'category': 'Drinks', 'price': 590, 'imageUrl': 'https://images.unsplash.com/photo-1623065422902-30a2d299bbe4?q=80&w=500', 'color': Colors.orange, 'icon': Icons.local_drink},
    {'id': 'DRK_2', 'name': 'Strawberry Shake', 'category': 'Drinks', 'price': 720, 'imageUrl': 'https://images.unsplash.com/photo-1553361371-9b22f78e8b1d?q=80&w=500', 'color': Colors.pink, 'icon': Icons.icecream},
    {'id': 'DRK_3', 'name': 'Mineral Water (Glass)', 'category': 'Drinks', 'price': 150, 'imageUrl': 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?q=80&w=500', 'color': Colors.blue, 'icon': Icons.water_drop},
    {'id': 'DRK_4', 'name': 'Fresh Green Tea', 'category': 'Drinks', 'price': 340, 'imageUrl': 'https://images.unsplash.com/photo-1564890369478-c89ca6d9cde9?q=80&w=500', 'color': Colors.green, 'icon': Icons.eco},
    
    // Snacks
    {'id': 'SNK_1', 'name': 'Nachos Grande', 'category': 'Snacks', 'price': 490, 'imageUrl': 'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?q=80&w=500', 'color': Colors.deepOrange, 'icon': Icons.fastfood},
    {'id': 'SNK_2', 'name': 'Garlic Naan', 'category': 'Snacks', 'price': 390, 'imageUrl': 'https://images.unsplash.com/photo-1601050690597-df0568f70950?q=80&w=500', 'color': Colors.brown, 'icon': Icons.bakery_dining},
    {'id': 'SNK_3', 'name': 'Chicken Wings', 'category': 'Snacks', 'price': 890, 'imageUrl': 'https://images.unsplash.com/photo-1527477396000-e27163b481c2?q=80&w=500', 'color': Colors.red, 'icon': Icons.restaurant},
    
    // Desserts
    {'id': 'DES_1', 'name': 'Ice Cream Sundae', 'category': 'Desserts', 'price': 540, 'imageUrl': 'https://images.unsplash.com/photo-1476124369491-e7addf5db371?q=80&w=500', 'color': Colors.pinkAccent, 'icon': Icons.icecream},
    {'id': 'DES_2', 'name': 'Fluffy Pancakes', 'category': 'Desserts', 'price': 670, 'imageUrl': 'https://images.unsplash.com/photo-1528207776546-365bb710ee93?q=80&w=500', 'color': Colors.amber, 'icon': Icons.bakery_dining},
    {'id': 'DES_3', 'name': 'Chocolate Brownie', 'category': 'Desserts', 'price': 430, 'imageUrl': 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?q=80&w=500', 'color': Colors.brown, 'icon': Icons.cake},
  ]);

  static void removeProduct(String id) {
    products.removeWhere((p) => p['id'] == id);
  }
}
