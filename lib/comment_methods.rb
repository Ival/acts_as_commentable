module ActsAsCommentable
  # including this module into your Comment model will give you finders and named scopes
  # useful for working with Comments.
  # The named scopes are:
  #   in_order: Returns comments in the order they were created (created_at ASC).
  #   recent: Returns comments by how recently they were created (created_at DESC).
  #   limit(N): Return no more than N comments.
  module Comment

    def self.included(comment_model)
      comment_model.extend Finders
      comment_model.extend CacheCounter
      comment_model.scope :in_order, -> { comment_model.order('created_at ASC') }
      comment_model.scope :recent, -> { comment_model.reorder('created_at DESC') }
      comment_model.after_create :counter_cache_after_destroy
      comment_model.after_destroy :counter_cache_after_destroy
    end

    module CacheCounter
      ###############################################################
      # Redis counter cache
      ###############################################################

      def self.redis
        Redis.new
      end

      def counter_cache_after_create
        cache_hash_key = "counter:comments"
        self.class.redis.hincrby cache_hash_key, "#{commentable_types}:#{commentable_id}", 1
      end

      def counter_cache_after_destroy
        cache_hash_key = "counter:comments"
        self.class.redis.hincrby cache_hash_key, "#{commentable_types}:#{commentable_id}", -1
      end
    end

    module Finders
      # Helper class method to lookup all comments assigned
      # to all commentable types for a given user.
      def find_comments_by_user(app_code, user)
        joins(:app).where(tb_app: {code: app_code}).
          where("user_id = ?").order("created_at DESC")
      end

      # Helper class method to look up all comments for 
      # commentable class name and commentable id.
      def find_comments_for_commentable(app_code, commentable_str, commentable_id)
        joins(:app).where(tb_app: {code: app_code})
        where(["commentable_type = ? and commentable_id = ?", commentable_str, commentable_id]).order("created_at DESC")
      end

      # Helper class method to look up a commentable object
      # given the commentable class name and id 
      def find_commentable(commentable_str, commentable_id)
        model = commentable_str.constantize
        model.respond_to?(:find_comments_for) ? model.find(commentable_id) : nil
      end
    end
  end
end
