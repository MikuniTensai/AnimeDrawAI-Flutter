import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/community_model.dart';
import '../repositories/community_repository.dart';

class CommunityUiState {
  final bool isLoading;
  final bool isRefreshing;
  final List<CommunityPost> posts;
  final String? error;

  const CommunityUiState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.posts = const [],
    this.error,
  });

  CommunityUiState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    List<CommunityPost>? posts,
    String? error,
  }) {
    return CommunityUiState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      posts: posts ?? this.posts,
      error: error,
    );
  }
}

class CommunityProvider extends ChangeNotifier {
  final CommunityRepository _repository;

  CommunityProvider(this._repository) {
    _loadPosts();
  }

  CommunityUiState _state = const CommunityUiState();
  CommunityUiState get state => _state;

  SortType _sortType = SortType.popular;
  SortType get sortType => _sortType;

  CommunityPost? _currentPost;
  CommunityPost? get currentPost => _currentPost;

  StreamSubscription<List<CommunityPost>>? _postsSubscription;
  final Set<String> _downloadedPostIds = {};

  void _setState(CommunityUiState newState) {
    _state = newState;
    notifyListeners();
  }

  void _loadPosts({bool refresh = false}) {
    if (refresh) {
      _setState(_state.copyWith(isRefreshing: true, error: null));
    } else {
      _setState(_state.copyWith(isLoading: _state.posts.isEmpty, error: null));
    }

    _postsSubscription?.cancel();
    _postsSubscription = _repository
        .getPostsStream(sortBy: _sortType)
        .listen(
          (posts) {
            _setState(
              _state.copyWith(
                isLoading: false,
                isRefreshing: false,
                posts: posts,
                error: null,
              ),
            );
          },
          onError: (e) {
            _setState(
              _state.copyWith(
                isLoading: false,
                isRefreshing: false,
                error: e.toString(),
              ),
            );
          },
        );
  }

  Future<void> changeSortType(SortType newSortType) async {
    if (_sortType != newSortType) {
      _sortType = newSortType;
      _loadPosts(refresh: true);
    }
  }

  void refreshPosts() => _loadPosts(refresh: true);

  Future<void> toggleLike(String postId) async {
    try {
      await _repository.toggleLike(postId);
      // Stream will auto-update the list
    } catch (e) {
      debugPrint('Failed to toggle like: $e');
    }
  }

  Future<void> downloadPost(CommunityPost post) async {
    if (_downloadedPostIds.contains(post.id)) return;
    _downloadedPostIds.add(post.id);
    try {
      await _repository.incrementDownload(post.id);
    } catch (e) {
      debugPrint('Failed to increment download: $e');
    }
  }

  bool isPostDownloaded(String postId) => _downloadedPostIds.contains(postId);

  Future<void> viewPost(String postId) async {
    try {
      await _repository.incrementView(postId);
    } catch (e) {
      debugPrint('Failed to increment view: $e');
    }
  }

  void selectPost(CommunityPost post) {
    _currentPost = post;
    notifyListeners();
  }

  Future<void> reportPost(String postId, String reason) async {
    try {
      await _repository.reportPost(postId, reason);
    } catch (e) {
      debugPrint('Failed to report post: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _repository.deletePost(postId);
    } catch (e) {
      _setState(_state.copyWith(error: e.toString()));
    }
  }

  Future<bool> hasLiked(String postId) async {
    return _repository.hasLiked(postId);
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    super.dispose();
  }
}
