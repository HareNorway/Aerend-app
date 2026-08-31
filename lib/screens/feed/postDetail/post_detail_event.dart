sealed class PostDetailEvent {
  const PostDetailEvent();
}

class PostDetailInitRequested extends PostDetailEvent {
  const PostDetailInitRequested();
}

class PostDetailRefreshRequested extends PostDetailEvent {
  const PostDetailRefreshRequested();
}

class PostDetailLikeToggleRequested extends PostDetailEvent {
  const PostDetailLikeToggleRequested();
}

class PostDetailCommentSubmitRequested extends PostDetailEvent {
  final String body;
  const PostDetailCommentSubmitRequested(this.body);
}

class PostDetailCommentDeleteRequested extends PostDetailEvent {
  final String commentId;
  const PostDetailCommentDeleteRequested(this.commentId);
}
