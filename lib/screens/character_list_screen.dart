import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/character.dart';
import '../services/rick_and_morty_service.dart';
import 'character_detail_screen.dart';

class CharacterListScreen extends StatefulWidget {
  const CharacterListScreen({super.key});

  @override
  State<CharacterListScreen> createState() => _CharacterListScreenState();
}

class _CharacterListScreenState extends State<CharacterListScreen> {
  final RickAndMortyService _service = RickAndMortyService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Character> _characters = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasNextPage = true;

  // Filter options
  String? _selectedStatus;
  String? _selectedSpecies;
  String? _selectedGender;

  final List<String> _statusOptions = ['alive', 'dead', 'unknown'];
  final List<String> _genderOptions = [
    'female',
    'male',
    'genderless',
    'unknown',
  ];

  @override
  void initState() {
    super.initState();
    _loadCharacters();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasNextPage) {
        _loadMoreCharacters();
      }
    }
  }

  Future<void> _loadCharacters({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _characters.clear();
      _hasNextPage = true;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      List<Character> characters;
      if (_searchController.text.isNotEmpty ||
          _selectedStatus != null ||
          _selectedSpecies != null ||
          _selectedGender != null) {
        characters = await _service.searchCharacters(
          name: _searchController.text.isNotEmpty
              ? _searchController.text
              : null,
          status: _selectedStatus,
          species: _selectedSpecies,
          gender: _selectedGender,
          page: _currentPage,
        );
      } else {
        characters = await _service.getAllCharacters(page: _currentPage);
      }

      setState(() {
        if (refresh) {
          _characters = characters;
        } else {
          _characters.addAll(characters);
        }
        _hasNextPage = characters.length == 20; // API returns 20 items per page
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadMoreCharacters() async {
    _currentPage++;
    await _loadCharacters();
  }

  void _performSearch() {
    _loadCharacters(refresh: true);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedSpecies = null;
      _selectedGender = null;
    });
    _loadCharacters(refresh: true);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'alive':
        return Colors.green;
      case 'dead':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rick & Morty Characters',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search characters...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
                const SizedBox(height: 12),
                // Filter Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Status Filter
                      _buildFilterChip(
                        'Status: ${_selectedStatus ?? 'All'}',
                        () => _showFilterDialog(
                          'Status',
                          _statusOptions,
                          _selectedStatus,
                          (value) {
                            setState(() => _selectedStatus = value);
                            _performSearch();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Gender Filter
                      _buildFilterChip(
                        'Gender: ${_selectedGender ?? 'All'}',
                        () => _showFilterDialog(
                          'Gender',
                          _genderOptions,
                          _selectedGender,
                          (value) {
                            setState(() => _selectedGender = value);
                            _performSearch();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Clear Filters
                      ActionChip(
                        label: const Text('Clear Filters'),
                        onPressed: _clearFilters,
                        backgroundColor: Colors.red.shade100,
                        labelStyle: TextStyle(color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Characters List
          Expanded(child: _buildCharactersList()),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.teal.shade100,
      labelStyle: TextStyle(color: Colors.teal.shade700),
    );
  }

  void _showFilterDialog(
    String title,
    List<String> options,
    String? selectedValue,
    Function(String?) onSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All'),
              leading: Radio<String?>(
                value: null,
                groupValue: selectedValue,
                onChanged: (value) {
                  onSelected(value);
                  Navigator.pop(context);
                },
              ),
            ),
            ...options.map(
              (option) => ListTile(
                title: Text(StringCapitalize(option).capitalize()),
                leading: Radio<String>(
                  value: option,
                  groupValue: selectedValue,
                  onChanged: (value) {
                    onSelected(value);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharactersList() {
    if (_isLoading && _characters.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError && _characters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error loading characters',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadCharacters(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_characters.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No characters found'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadCharacters(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _characters.length + (_hasNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _characters.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final character = _characters[index];
          return _buildCharacterCard(character);
        },
      ),
    );
  }

  Widget _buildCharacterCard(Character character) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CharacterDetailScreen(character: character),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Character Image
              Hero(
                tag: 'character-${character.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: character.image,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.person, size: 40),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.error, size: 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Character Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(character.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${character.status} - ${character.species}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last known location:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      character.location.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

extension StringCapitalize on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
