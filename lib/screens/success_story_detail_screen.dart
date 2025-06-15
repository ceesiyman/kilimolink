import 'package:flutter/material.dart';
import '../model/success_story_model.dart';
import '../service/api_service.dart';

class SuccessStoryDetailScreen extends StatefulWidget {
  final SuccessStory story;

  const SuccessStoryDetailScreen({Key? key, required this.story}) : super(key: key);

  @override
  _SuccessStoryDetailScreenState createState() => _SuccessStoryDetailScreenState();
}

class _SuccessStoryDetailScreenState extends State<SuccessStoryDetailScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  late SuccessStory _story;
  bool _isLoading = false;
  bool _isCommenting = false;
  bool _isReplying = false;
  int? _replyingToCommentId;
  Set<int> _expandedReplies = {}; // Track which comments have expanded replies

  @override
  void initState() {
    super.initState();
    _story = widget.story;
    _loadFreshStoryData();
  }

  Future<void> _loadFreshStoryData() async {
    try {
      final freshStory = await apiService.fetchSuccessStoryFromApi(_story.id);
      setState(() {
        _story = freshStory;
      });
    } catch (e) {
      print('Error loading fresh story data: $e');
      // Keep the original story data if fresh load fails
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await apiService.toggleSuccessStoryLikeFromApi(_story.id);
      
      setState(() {
        _story = SuccessStory(
          id: _story.id,
          userId: _story.userId,
          title: _story.title,
          content: _story.content,
          location: _story.location,
          cropType: _story.cropType,
          yieldImprovement: _story.yieldImprovement,
          yieldUnit: _story.yieldUnit,
          isFeatured: _story.isFeatured,
          viewsCount: _story.viewsCount,
          likesCount: response['likesCount'],
          commentsCount: _story.commentsCount,
          createdAt: _story.createdAt,
          updatedAt: _story.updatedAt,
          user: _story.user,
          images: _story.images,
          comments: _story.comments,
          isLiked: !(_story.isLiked ?? false),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'])),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error toggling like: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isCommenting = true;
    });

    try {
      final newComment = await apiService.addSuccessStoryCommentFromApi(
        storyId: _story.id,
        comment: _commentController.text.trim(),
        parentId: _replyingToCommentId, // This will be null for regular comments
      );

      if (_replyingToCommentId != null) {
        // This is a reply - update the parent comment
        final updatedComments = _story.comments.map((comment) {
          if (comment.id == _replyingToCommentId) {
            return StoryComment(
              id: comment.id,
              successStoryId: comment.successStoryId,
              userId: comment.userId,
              comment: comment.comment,
              parentId: comment.parentId,
              createdAt: comment.createdAt,
              updatedAt: comment.updatedAt,
              user: comment.user,
              replies: [...comment.replies, newComment],
            );
          }
          return comment;
        }).toList();

        setState(() {
          _story = SuccessStory(
            id: _story.id,
            userId: _story.userId,
            title: _story.title,
            content: _story.content,
            location: _story.location,
            cropType: _story.cropType,
            yieldImprovement: _story.yieldImprovement,
            yieldUnit: _story.yieldUnit,
            isFeatured: _story.isFeatured,
            viewsCount: _story.viewsCount,
            likesCount: _story.likesCount,
            commentsCount: _story.commentsCount + 1,
            createdAt: _story.createdAt,
            updatedAt: _story.updatedAt,
            user: _story.user,
            images: _story.images,
            comments: updatedComments,
            isLiked: _story.isLiked,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reply added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // This is a regular comment
        setState(() {
          _story = SuccessStory(
            id: _story.id,
            userId: _story.userId,
            title: _story.title,
            content: _story.content,
            location: _story.location,
            cropType: _story.cropType,
            yieldImprovement: _story.yieldImprovement,
            yieldUnit: _story.yieldUnit,
            isFeatured: _story.isFeatured,
            viewsCount: _story.viewsCount,
            likesCount: _story.likesCount,
            commentsCount: _story.commentsCount + 1,
            createdAt: _story.createdAt,
            updatedAt: _story.updatedAt,
            user: _story.user,
            images: _story.images,
            comments: [..._story.comments, newComment],
            isLiked: _story.isLiked,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comment added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _commentController.clear();
      _replyingToCommentId = null; // Reset reply mode
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding ${_replyingToCommentId != null ? 'reply' : 'comment'}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCommenting = false;
      });
    }
  }

  Future<void> _addReply(int parentCommentId, String parentCommentText) async {
    // Set the reply mode and show the input field
    setState(() {
      _replyingToCommentId = parentCommentId;
    });
    
    // Update the comment controller hint text
    _commentController.text = '';
    
    // Scroll to the comment input field
    // Note: In a real implementation, you might want to add a ScrollController
    // to programmatically scroll to the input field
  }

  void _toggleReplies(int commentId) {
    setState(() {
      if (_expandedReplies.contains(commentId)) {
        _expandedReplies.remove(commentId);
      } else {
        _expandedReplies.add(commentId);
      }
    });
  }

  Widget _buildImageGallery() {
    if (_story.images.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _story.images.length,
            itemBuilder: (context, index) {
              final image = _story.images[index];
              return Container(
                width: 200,
                margin: EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: image.imagePath.isNotEmpty
                            ? Image.network(
                                image.imagePath,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading detail image: ${image.imagePath}');
                                  return Container(
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey[600],
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey[600],
                                ),
                              ),
                      ),
                    ),
                    if (image.caption != null && image.caption!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          image.caption!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Comments (${_story.comments.length})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (_story.comments.isEmpty)
          Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No comments yet. Be the first to comment!',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _story.comments.length,
            itemBuilder: (context, index) {
              final comment = _story.comments[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: comment.user.imageUrl.isNotEmpty
                                ? NetworkImage(comment.user.imageUrl)
                                : null,
                            radius: 16,
                            onBackgroundImageError: (_, __) {
                              print('Error loading comment user image: ${comment.user.imageUrl}');
                            },
                            child: comment.user.imageUrl.isEmpty
                                ? Icon(Icons.person, color: Colors.grey, size: 16)
                                : null,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment.user.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${comment.createdAt.day}/${comment.createdAt.month}/${comment.createdAt.year}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(comment.comment),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _addReply(comment.id, comment.comment),
                            icon: Icon(Icons.reply, size: 16),
                            label: Text('Reply'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          if (comment.replies.isNotEmpty) ...[
                            SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _toggleReplies(comment.id),
                              icon: Icon(
                                _expandedReplies.contains(comment.id) 
                                    ? Icons.expand_less 
                                    : Icons.expand_more,
                                size: 16,
                              ),
                              label: Text(
                                _expandedReplies.contains(comment.id) 
                                    ? 'Hide replies' 
                                    : 'Show replies',
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue,
                                padding: EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ],
                          Spacer(),
                          if (comment.replies.isNotEmpty)
                            Text(
                              _expandedReplies.contains(comment.id)
                                  ? '${comment.replies.length} replies (shown)'
                                  : '${comment.replies.length} replies (hidden)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      if (comment.replies.isNotEmpty && !_expandedReplies.contains(comment.id)) ...[
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.subdirectory_arrow_right,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${comment.replies.length} ${comment.replies.length == 1 ? 'reply' : 'replies'} hidden',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (comment.replies.isNotEmpty && _expandedReplies.contains(comment.id)) ...[
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Column(
                            children: comment.replies.map((reply) {
                              return Card(
                                color: Colors.grey[50],
                                margin: EdgeInsets.only(bottom: 4),
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundImage: reply.user.imageUrl.isNotEmpty
                                                ? NetworkImage(reply.user.imageUrl)
                                                : null,
                                            radius: 12,
                                            onBackgroundImageError: (_, __) {
                                              print('Error loading reply user image: ${reply.user.imageUrl}');
                                            },
                                            child: reply.user.imageUrl.isEmpty
                                                ? Icon(Icons.person, color: Colors.grey, size: 12)
                                                : null,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  reply.user.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Text(
                                                  '${reply.createdAt.day}/${reply.createdAt.month}/${reply.createdAt.year}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        reply.comment,
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Success Story'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and featured badge
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: _story.user.imageUrl.isNotEmpty
                        ? NetworkImage(_story.user.imageUrl)
                        : null,
                    radius: 25,
                    onBackgroundImageError: (_, __) {
                      print('Error loading story user image: ${_story.user.imageUrl}');
                    },
                    child: _story.user.imageUrl.isEmpty
                        ? Icon(Icons.person, color: Colors.grey, size: 30)
                        : null,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _story.user.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_story.location != null)
                          Text(
                            _story.location!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        Text(
                          '${_story.createdAt.day}/${_story.createdAt.month}/${_story.createdAt.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_story.isFeatured)
                    Chip(
                      label: Text('Featured'),
                      backgroundColor: Colors.amber[100],
                      labelStyle: TextStyle(color: Colors.amber[800]),
                    ),
                ],
              ),
            ),

            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _story.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _story.content,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Tags/Chips
            if (_story.cropType != null || _story.yieldImprovement != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_story.cropType != null)
                      Chip(
                        label: Text(_story.cropType!),
                        backgroundColor: Colors.green[50],
                        labelStyle: TextStyle(color: Colors.green[700]),
                      ),
                    if (_story.yieldImprovement != null)
                      Chip(
                        label: Text('${_story.yieldImprovement} ${_story.yieldUnit ?? 'units'}'),
                        backgroundColor: Colors.blue[50],
                        labelStyle: TextStyle(color: Colors.blue[700]),
                      ),
                  ],
                ),
              ),
            SizedBox(height: 16),

            // Image Gallery
            _buildImageGallery(),
            SizedBox(height: 16),

            // Interaction Stats
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      (_story.isLiked ?? false) ? Icons.thumb_up : Icons.thumb_up_outlined,
                      color: (_story.isLiked ?? false) ? Colors.green : null,
                    ),
                    onPressed: _isLoading ? null : _toggleLike,
                  ),
                  Text('${_story.likesCount}'),
                  SizedBox(width: 16),
                  Icon(Icons.comment_outlined),
                  Text('${_story.commentsCount}'),
                  SizedBox(width: 16),
                  Icon(Icons.visibility_outlined),
                  Text('${_story.viewsCount}'),
                ],
              ),
            ),

            // Comments Section
            _buildCommentsSection(),
            SizedBox(height: 16),

            // Add Comment Section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Column(
                children: [
                  if (_replyingToCommentId != null) ...[
                    Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.reply, color: Colors.blue[700], size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Replying to a comment',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.blue[700], size: 16),
                            onPressed: () {
                              setState(() {
                                _replyingToCommentId = null;
                                _commentController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: _replyingToCommentId != null 
                                ? 'Write your reply...' 
                                : 'Add a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: _isCommenting ? null : _addComment,
                        icon: _isCommenting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _replyingToCommentId != null ? Icons.reply : Icons.send, 
                                color: Colors.green,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 