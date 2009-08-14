ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :dbfile => ':memory:')

describe Bullet do
  def setup_db
    ActiveRecord::Schema.define(:version => 1) do
      create_table :categories do |t|
        t.column :name, :string
      end
      
      create_table :posts do |t|
        t.column :name, :string
        t.column :category_id, :integer
      end

      create_table :comments do |t|
        t.column :name, :string
        t.column :post_id, :integer
      end

      create_table :entries do |t|
        t.column :name, :string
        t.column :category_id, :integer
      end
    end
  end

  def teardown_db
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end
  
  class Category < ActiveRecord::Base
    has_many :posts
    has_many :entries
  end

  class Post < ActiveRecord::Base
    belongs_to :category
    has_many :comments
  end
  
  class Entry < ActiveRecord::Base
    belongs_to :category
  end

  class Comment < ActiveRecord::Base
    belongs_to :post
  end
  
  before(:all) do
    setup_db
    
    category = Category.create(:name => 'first')
    
    post = category.posts.create(:name => 'first')
    post = category.posts.create(:name => 'second')
    
    post.comments.create(:name => 'first')
    post.comments.create(:name => 'second')
    post.comments.create(:name => 'third')
    post.comments.create(:name => 'fourth')
    
    entry = category.entries.create(:name => 'first')
    entry = category.entries.create(:name => 'second')
  end
  
  after(:all) do
    teardown_db
  end
  
  context "post => comments" do
    it "should detect preload with post => comments" do
      Bullet::Association.start_request
      Post.find(:all, :include => :comments).each do |post|
        post.comments.collect(&:name)
      end
      Bullet::Association.unpreload_associations.should be_empty
      Bullet::Association.end_request
    end
  
    it "should detect no preload post => comments" do
      Bullet::Association.start_request
      Post.find(:all).each do |post|
        post.comments.collect(&:name)
      end
      Bullet::Association.unpreload_associations.should_not be_empty
      Bullet::Association.end_request
    end
  end
  
  context "category => posts => comments" do
    it "should detect preload with category => posts => comments" do
      Bullet::Association.start_request
      Category.find(:all, :include => {:posts => :comments}) do |category|
        category.posts.each do |post|
          post.comments.collect(&:name)
        end
      end
      Bullet::Association.unpreload_associations.should be_empty
      Bullet::Association.end_request
    end
  
    it "should detect preload category => posts, but no post => comments" do
      Bullet::Association.start_request
      Category.find(:all, :include => :posts).each do |category|
        category.posts.each do |post|
          post.comments.collect(&:name)
        end
      end
      Bullet::Association.unpreload_associations.should_not be_empty
      Bullet::Association.end_request
    end
  
    it "should detect no preload category => posts => comments" do
      Bullet::Association.start_request
      Category.find(:all).each do |category|
        category.posts.each do |post|
          post.comments.collect(&:name)
        end
      end
      Bullet::Association.unpreload_associations.should_not be_empty
      Bullet::Association.end_request
    end
  end
  
  context "category => posts, category => entries" do
    it "should detect preload with category => [posts, entries]" do
      Bullet::Association.start_request
      Category.find(:all, :include => [:posts, :entries]).each do |category|
        category.posts.collect(&:name)
        category.entries.collect(&:name)
      end
      Bullet::Association.unpreload_associations.should be_empty
      Bullet::Association.end_request
    end

    it "should detect preload with category => posts, but no category => entries" do
      Bullet::Association.start_request
      Category.find(:all, :include => :posts).each do |category|
        category.posts.collect(&:name)
        category.entries.collect(&:name)
      end
      Bullet::Association.unpreload_associations.should_not be_empty
      Bullet::Association.end_request
    end

    it "should detect no preload with category => [posts, entries]" do
      Bullet::Association.start_request
      Category.find(:all).each do |category|
        category.posts.collect(&:name)
        category.entries.collect(&:name)
      end
      Bullet::Association.unpreload_associations.should_not be_empty
      Bullet::Association.end_request
    end
  end
end