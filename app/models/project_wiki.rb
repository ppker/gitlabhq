# frozen_string_literal: true

class ProjectWiki < Wiki
  self.container_class = Project
  alias_method :project, :container

  # Project wikis are tied to the main project storage
  delegate :storage, :repository_storage, :hashed_storage?, :lfs_enabled?, to: :container

  override :disk_path
  def disk_path(*args, &block)
    container.disk_path + '.wiki'
  end

  override :create_wiki_repository
  def create_wiki_repository
    super

    track_wiki_repository
  end

  override :after_wiki_activity
  def after_wiki_activity
    # Update activity columns, this is done synchronously to avoid
    # replication delays in Geo.
    project.touch(:last_activity_at, :last_repository_updated_at)
  end

  override :after_post_receive
  def after_post_receive
    # Update storage statistics
    ProjectCacheWorker.perform_async(project.id, [], %w[wiki_size])

    # This call is repeated for post-receive, to make sure we're updating
    # the activity columns for Git pushes as well.
    after_wiki_activity
  end

  private

  def track_wiki_repository
    return unless ::Gitlab::Database.read_write?
    return if container.wiki_repository

    # This is the ActiveRecord auto-generated method for a Project's has_one :wiki_repository
    container.create_wiki_repository!
  end
end
