import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:xhs/components/tweetcard.dart';
import 'package:xhs/services/api_service.dart';
import 'package:xhs/views/blog_page.dart';

/// 博客数据模型
class Blog {
  final int id;
  final int uid;
  final String title;
  final String content;
  int likes;
  final bool draft;
  final bool isVideo;
  final String authorName;
  final String authorAvatar;
  final List<String> imageUrls;
  final String videoUrl;
  bool liked;
  bool favorited;
  bool followed;

  Blog({
    required this.id,
    required this.uid,
    required this.title,
    required this.content,
    required this.likes,
    required this.draft,
    required this.isVideo,
    required this.authorName,
    required this.authorAvatar,
    required this.imageUrls,
    required this.videoUrl,
    required this.liked,
    required this.favorited,
    required this.followed,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final images = (json['images'] as List<dynamic>?) ?? [];
    return Blog(
      id: json['id'] as int,
      uid: json['uid'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      likes: json['likes'] as int? ?? 0,
      draft: json['draft'] as bool? ?? false,
      isVideo: json['isVideo'] as bool? ?? false,
      authorName: user?['username'] as String? ?? '匿名',
      authorAvatar: user?['avatar'] as String? ?? '',
      imageUrls: images.map((e) => e['url'] as String).toList(),
      videoUrl: json['videoUrl'] as String? ?? '',
      liked: json['liked'] as bool? ?? false,
      favorited: json['favorited'] as bool? ?? false,
      followed: json['followed'] as bool? ?? false,
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _history = [];
  final _storage = const FlutterSecureStorage();
  
  List<Blog> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  List<String> _popularKeywords = [];

  // 热门搜索关键词（作为备用）
  final List<String> _hotKeywords = ['美食', '旅行', '穿搭', '护肤', '健身', '读书', '摄影', '手工', '宠物', '园艺'];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _loadPopularKeywords();
    _searchController.addListener(_onSearchTextChanged);
  }

  Future<void> _loadSearchHistory() async {
    try {
      final auth = await ApiService.getAuthObject();
      final uid = auth['id'].toString();
      final historyData = await ApiService.getSearchHistory(uid);
      setState(() {
        _history = historyData.map((e) => e['keyword'] as String).toList();
      });
    } catch (e) {
      debugPrint('加载搜索历史失败: $e');
    }
  }

  Future<void> _loadPopularKeywords() async {
    try {
      final auth = await ApiService.getAuthObject();
      final uid = auth['id'].toString();
      final popularData = await ApiService.getPopularKeywords(uid);
      setState(() {
        _popularKeywords = popularData.map((e) => e['keyword'] as String).toList();
      });
    } catch (e) {
      debugPrint('加载热门关键词失败: $e');
    }
  }

  void _onSearchTextChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _suggestions = [];
      });
      return;
    }

    // 从历史记录和热门关键词中筛选建议
    final allKeywords = [..._history, ..._popularKeywords, ..._hotKeywords];
    final filtered = allKeywords
        .where((keyword) => keyword.toLowerCase().contains(query.toLowerCase()))
        .where((keyword) => keyword != query)
        .take(5)
        .toList();

    setState(() {
      _suggestions = filtered;
      _showSuggestions = filtered.isNotEmpty;
    });
  }

  Future<void> _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _showSuggestions = false;
    });

    try {
      final auth = await ApiService.getAuthObject();
      final uid = auth['id'].toString();
      
      final data = await ApiService.searchBlogs(keyword.trim(), uid);
      final blogs = data.map((e) => Blog.fromJson(e as Map<String, dynamic>)).toList();
      
      setState(() {
        _searchResults = blogs;
        _isSearching = false;
      });
      
      // 搜索完成后重新加载历史记录
      await _loadSearchHistory();
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('搜索失败：$e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.grey,
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '搜索内容',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                _performSearch(_searchController.text);
              },
            ),
          ),
          onSubmitted: (value) {
            _performSearch(value);
          },
        ),
      ),
      body: _hasSearched 
          ? _buildSearchResults() 
          : _showSuggestions 
              ? _buildSearchSuggestions() 
              : _buildSearchHistory(),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // 搜索结果标题
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '搜索结果 (${_searchResults.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        // 搜索结果列表
        Expanded(
          child: _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        '没有找到相关内容',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '试试其他关键词',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: _searchResults.where((blog) => !blog.isVideo).length,
                  itemBuilder: (context, index) {
                    final filteredBlogs = _searchResults.where((blog) => !blog.isVideo).toList();
                    final blog = filteredBlogs[index];
                    return TweetCard(
                      imageUrl: blog.imageUrls.isNotEmpty ? blog.imageUrls.first : '',
                      title: blog.title,
                      avatarUrl: blog.authorAvatar,
                      username: blog.authorName,
                      likes: blog.likes,
                      liked: blog.liked,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlogPage(
                              blogId: blog.id,
                              authorName: blog.authorName,
                              authorAvatar: blog.authorAvatar,
                              imageUrls: blog.imageUrls,
                              title: blog.title,
                              content: blog.content,
                            ),
                          ),
                        );
                        if (result != null && result is Map) {
                          // 更新搜索结果中的点赞状态
                          setState(() {
                            blog.liked = result['liked'];
                            blog.likes = result['likes'];
                          });
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchHistory() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('历史搜索', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (_history.isNotEmpty)
                TextButton(
                  onPressed: _clearAllHistory,
                  child: const Text('清除全部', style: TextStyle(color: Colors.grey)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '暂无搜索历史',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _history.map((keyword) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = keyword;
                    _performSearch(keyword);
                  },
                  child: Chip(
                    label: Text(keyword),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () {
                      _removeFromHistory(keyword);
                    },
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          const Text('热门搜索', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (_popularKeywords.isNotEmpty ? _popularKeywords : _hotKeywords).map((keyword) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = keyword;
                  _performSearch(keyword);
                },
                child: Chip(
                  label: Text(keyword),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('搜索建议', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((keyword) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = keyword;
                  _performSearch(keyword);
                },
                child: Chip(
                  label: Text(keyword),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _addToHistory(String keyword) {
    if (keyword.isNotEmpty && !_history.contains(keyword)) {
      setState(() {
        _history.insert(0, keyword);
        if (_history.length > 10) {
          _history.removeLast();
        }
      });
    }
  }

  void _removeFromHistory(String keyword) {
    setState(() {
      _history.remove(keyword);
    });
  }

  void _clearAllHistory() {
    setState(() {
      _history.clear();
    });
  }
}
