import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final MapController _mapController = MapController();
  String _filter = 'all';

  List<ItemModel> get _filteredItems {
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1F26),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'map view',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: StreamBuilder<List<ItemModel>>(
        stream: _firestoreService.getItems(filter: 'all'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
            );
          }

          final allItems = snapshot.data ?? [];

          // apply filter
          final items = _filter == 'all'
              ? allItems
              : allItems.where((i) => i.type == _filter).toList();

          return Column(
            children: [
              // filter tabs
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                color: const Color(0xFF0F0F0F),
                child: Row(
                  children: [
                    _filterTab('all', 'all'),
                    const SizedBox(width: 8),
                    _filterTab('found', 'found'),
                    const SizedBox(width: 8),
                    _filterTab('lost', 'lost'),
                    const Spacer(),
                    Row(
                      children: [
                        _legendDot(const Color(0xFF22D3EE)),
                        const SizedBox(width: 4),
                        const Text(
                          'found',
                          style: TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _legendDot(const Color(0xFFF87171)),
                        const SizedBox(width: 4),
                        const Text(
                          'lost',
                          style: TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // map
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: items.isNotEmpty &&
                            items.first.latitude != 0
                        ? LatLng(
                            items.first.latitude,
                            items.first.longitude,
                          )
                        : const LatLng(6.9271, 79.8612),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.back_to_you',
                    ),
                    MarkerLayer(
                      markers: items
                          .where((item) =>
                              item.latitude != 0 && item.longitude != 0)
                          .map((item) {
                        bool isFound = item.type == 'found';
                        return Marker(
                          point: LatLng(item.latitude, item.longitude),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _showItemBottomSheet(item),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isFound
                                    ? const Color(0xFF22D3EE)
                                    : const Color(0xFFF87171),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  isFound ? Icons.check : Icons.search,
                                  color: Colors.black,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // items count bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: const Color(0xFF0F0F0F),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF22D3EE),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${items.where((i) => i.latitude != 0).length} items on map',
                      style: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterTab(String value, String label) {
    bool isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF22D3EE)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF22D3EE)
                : const Color(0xFF2A2A2A),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : const Color(0xFF555555),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  void _showItemBottomSheet(ItemModel item) {
    bool isFound = item.type == 'found';
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isFound
                        ? const Color(0xFF052E16)
                        : const Color(0xFF450A0A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isFound ? 'found' : 'lost',
                    style: TextStyle(
                      color: isFound
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFF87171),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 13,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF444444),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.location,
                    style: const TextStyle(
                      color: Color(0xFF444444),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  item.timeAgo,
                  style: const TextStyle(
                    color: Color(0xFF444444),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/item-detail',
                    arguments: item,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22D3EE),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'view full details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}