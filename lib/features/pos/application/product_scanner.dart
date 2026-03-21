// lib/features/pos/application/product_scanner.dart
import '../application/pos_provider.dart';
import '../../inventory/application/inventory_provider.dart';
import '../../inventory/data/repositories/product_repository.dart';

class ProductScanner {
  final ProductRepository _productRepository;
  final PosProvider _posProvider;

  ProductScanner({
    required ProductRepository productRepository,
    required PosProvider posProvider,
  })  : _productRepository = productRepository,
        _posProvider = posProvider;

  Future<bool> handleBarcode(String barcode, {int quantity = 1}) async {
    try {
      final variant = await _productRepository.getVariantByBarcode(barcode);
      if (variant == null) return false;

      // Get product details (could be cached or fetched)
      final productWithVariants = await _productRepository.getProductWithVariants(variant.productId);
      if (productWithVariants == null) return false;

      final product = productWithVariants['product'];

      final stockLevel = await _productRepository.getStockLevelByVariantId(variant.id);
      final int availableStock = stockLevel?.availablePieces ?? 0;

      if (availableStock < quantity) return false;

      _posProvider.addToCart(
        variantId: variant.id,
        productName: product.name,
        productSku: product.baseSku,
        variantName: variant.variantName ?? '',
        unitPrice: variant.retailPrice,
        quantity: quantity,
        profitMargin: variant.retailPrice - variant.costPrice,
        availableStock: availableStock,
      );

      return true;
    } catch (e) {
      return false;
    }
  }
}
