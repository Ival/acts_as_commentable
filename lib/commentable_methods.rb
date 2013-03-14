require 'active_record'

# ActsAsCommentable
module Juixe
  module Acts #:nodoc:
    module Commentable #:nodoc:

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_commentable
          has_many :comments, class_name: "DataSource::Comment", as: :commentable, dependent: :destroy

          class_eval %{
            delegate :code, to: :app, prefix: true, allow_nil: false

            def self.find_comments_for(obj)
              commentable = self.base_class.name
              Comment.find_comments_for_commentable(obj.app_code, commentable, obj.id)
            end

            def self.find_comments_by_user(app_code, user) 
              commentable = self.base_class.name
              Comment.joins(:app).where(tb_app: {code: app_code}).
                where(["user_id = ? and commentable_type = ?", user.id, commentable]).order("created_at DESC")
            end

            def comments_ordered_by_submitted
              Comment.find_comments_for_commentable(app_code, self.class.name, id)
            end

            def add_comments(comment)
              comments << comment
            end
          }
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, Juixe::Acts::Commentable)
