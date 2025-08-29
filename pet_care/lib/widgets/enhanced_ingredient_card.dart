import 'package:flutter/material.dart';

class EnhancedIngredientCard extends StatefulWidget {
  final Map<String, dynamic> ingredient;
  final bool isUsedInMeal;

  const EnhancedIngredientCard({
    Key? key,
    required this.ingredient,
    this.isUsedInMeal = false,
  }) : super(key: key);

  @override
  State<EnhancedIngredientCard> createState() => _EnhancedIngredientCardState();
}

class _EnhancedIngredientCardState extends State<EnhancedIngredientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _animationController.reverse();
        _showIngredientDetails(context);
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isPressed 
                  ? (widget.isUsedInMeal ? Colors.green.shade100 : Colors.grey.shade100)
                  : (widget.isUsedInMeal ? Colors.green.shade50 : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isUsedInMeal 
                      ? Colors.green.shade300 
                      : Colors.grey.shade200,
                  width: widget.isUsedInMeal ? 2 : 1,
                ),
                boxShadow: [
                  if (widget.isUsedInMeal)
                    BoxShadow(
                      color: Colors.green.withOpacity(_isPressed ? 0.3 : 0.2),
                      blurRadius: _isPressed ? 12 : 8,
                      offset: Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ingredient Icon/Image
                  Stack(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getIngredientColor(widget.ingredient['category']),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: _getIngredientColor(widget.ingredient['category']).withOpacity(0.3),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getIngredientIcon(widget.ingredient['category']),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      if (widget.isUsedInMeal)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  
                  // Ingredient Name
                  Text(
                    widget.ingredient['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.isUsedInMeal ? Colors.green.shade800 : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 4),
                  
                  // Stock Info
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStockColor(widget.ingredient['stock']),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.ingredient['stock'] ?? 0} ${widget.ingredient['unit'] ?? ''}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  SizedBox(height: 4),
                  
                  // Nutritional highlights
                  if (widget.ingredient['protein'] != null || 
                      widget.ingredient['fiber'] != null ||
                      widget.ingredient['fat'] != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (widget.ingredient['protein'] != null)
                          _buildNutrientBadge('P', '${widget.ingredient['protein']}%', Colors.red.shade300),
                        if (widget.ingredient['fat'] != null)
                          _buildNutrientBadge('F', '${widget.ingredient['fat']}%', Colors.orange.shade300),
                        if (widget.ingredient['fiber'] != null)
                          _buildNutrientBadge('Fb', '${widget.ingredient['fiber']}%', Colors.green.shade300),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNutrientBadge(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getIngredientColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'protein':
      case 'meat':
        return Colors.red.shade400;
      case 'vegetables':
      case 'vegetable':
        return Colors.green.shade400;
      case 'fruits':
      case 'fruit':
        return Colors.orange.shade400;
      case 'grains':
      case 'grain':
        return Colors.brown.shade400;
      case 'dairy':
        return Colors.blue.shade400;
      case 'supplements':
      case 'supplement':
        return Colors.purple.shade400;
      case 'oils':
      case 'oil':
        return Colors.yellow.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  IconData _getIngredientIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'protein':
      case 'meat':
        return Icons.set_meal;
      case 'vegetables':
      case 'vegetable':
        return Icons.eco;
      case 'fruits':
      case 'fruit':
        return Icons.apple;
      case 'grains':
      case 'grain':
        return Icons.grain;
      case 'dairy':
        return Icons.local_drink;
      case 'supplements':
      case 'supplement':
        return Icons.medical_services;
      case 'oils':
      case 'oil':
        return Icons.opacity;
      default:
        return Icons.circle;
    }
  }

  Color _getStockColor(dynamic stock) {
    if (stock == null) return Colors.grey.shade400;
    
    int stockValue = 0;
    if (stock is num) {
      stockValue = stock.toInt();
    } else if (stock is String) {
      stockValue = int.tryParse(stock) ?? 0;
    }
    
    if (stockValue == 0) return Colors.red.shade400;
    if (stockValue < 10) return Colors.orange.shade400;
    if (stockValue < 50) return Colors.yellow.shade600;
    return Colors.green.shade400;
  }

  void _showIngredientDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => IngredientDetailSheet(ingredient: widget.ingredient),
    );
  }
}

class IngredientDetailSheet extends StatelessWidget {
  final Map<String, dynamic> ingredient;

  const IngredientDetailSheet({Key? key, required this.ingredient}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20),
          
          // Header
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getIngredientColor(ingredient['category']),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  _getIngredientIcon(ingredient['category']),
                  color: Colors.white,
                  size: 30,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredient['name'] ?? 'Unknown Ingredient',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ingredient['category'] ?? 'Unknown Category',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Nutritional Information
          if (ingredient['protein'] != null ||
              ingredient['fat'] != null ||
              ingredient['fiber'] != null ||
              ingredient['moisture'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nutritional Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    if (ingredient['protein'] != null)
                      Expanded(child: _buildNutrientCard('Protein', '${ingredient['protein']}%', Colors.red.shade400)),
                    if (ingredient['fat'] != null)
                      Expanded(child: _buildNutrientCard('Fat', '${ingredient['fat']}%', Colors.orange.shade400)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    if (ingredient['fiber'] != null)
                      Expanded(child: _buildNutrientCard('Fiber', '${ingredient['fiber']}%', Colors.green.shade400)),
                    if (ingredient['moisture'] != null)
                      Expanded(child: _buildNutrientCard('Moisture', '${ingredient['moisture']}%', Colors.blue.shade400)),
                  ],
                ),
              ],
            ),
          
          SizedBox(height: 20),
          
          // Stock and Unit
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Available Stock',
                  '${ingredient['stock'] ?? 0} ${ingredient['unit'] ?? ''}',
                  Icons.inventory_2,
                  _getStockColor(ingredient['stock']),
                ),
              ),
              SizedBox(width: 12),
              if (ingredient['cost'] != null)
                Expanded(
                  child: _buildInfoCard(
                    'Cost per Unit',
                    '\$${ingredient['cost']}',
                    Icons.attach_money,
                    Colors.green.shade400,
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Benefits
          if (ingredient['benefits'] != null && ingredient['benefits'].toString().isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Benefits',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    ingredient['benefits'].toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNutrientCard(String label, String value, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getIngredientColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'protein':
      case 'meat':
        return Colors.red.shade400;
      case 'vegetables':
      case 'vegetable':
        return Colors.green.shade400;
      case 'fruits':
      case 'fruit':
        return Colors.orange.shade400;
      case 'grains':
      case 'grain':
        return Colors.brown.shade400;
      case 'dairy':
        return Colors.blue.shade400;
      case 'supplements':
      case 'supplement':
        return Colors.purple.shade400;
      case 'oils':
      case 'oil':
        return Colors.yellow.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  IconData _getIngredientIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'protein':
      case 'meat':
        return Icons.set_meal;
      case 'vegetables':
      case 'vegetable':
        return Icons.eco;
      case 'fruits':
      case 'fruit':
        return Icons.apple;
      case 'grains':
      case 'grain':
        return Icons.grain;
      case 'dairy':
        return Icons.local_drink;
      case 'supplements':
      case 'supplement':
        return Icons.medical_services;
      case 'oils':
      case 'oil':
        return Icons.opacity;
      default:
        return Icons.circle;
    }
  }

  Color _getStockColor(dynamic stock) {
    if (stock == null) return Colors.grey.shade400;
    
    int stockValue = 0;
    if (stock is num) {
      stockValue = stock.toInt();
    } else if (stock is String) {
      stockValue = int.tryParse(stock) ?? 0;
    }
    
    if (stockValue == 0) return Colors.red.shade400;
    if (stockValue < 10) return Colors.orange.shade400;
    if (stockValue < 50) return Colors.yellow.shade600;
    return Colors.green.shade400;
  }
}
