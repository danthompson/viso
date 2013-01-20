require 'content/markdown'

describe Content::Markdown do
  before do
    module FakeSuper
      def content() 'super content' end
    end

    class FakeContent
      include FakeSuper
      include Content::Markdown

      def initialize(url) @url = url end
      def raw() '# Chapter 1' end
    end
  end

  after do
    Object.send :remove_const, :FakeContent
    Object.send :remove_const, :FakeSuper
  end


  describe '#content' do
    it 'generates markdown' do
      EM.synchrony do
        drop = FakeContent.new 'http://cl.ly/hhgttg/chapter1.md'
        markdown = '<h1>Chapter 1</h1>'
        EM.stop

        drop.content.strip.should == markdown
      end
    end

    context 'when emoji are present' do
      before do
        Content::EmojiedHTML.any_instance.stub(has_emoji_images?: true)
      end

      it 'interpolates emoji icons' do
        raw   = '# Chapter 1 :books:'
        emoji = '<img alt="books" src="images/emoji/books.png" ' \
                'width="20" height="20" class="emoji" />'

        EM.synchrony do
          drop = FakeContent.new 'http://cl.ly/hhgttg/chapter1.md'
          drop.stub! :raw => raw
          EM.stop

          drop.content.should include(emoji)
        end
      end

      it 'does not interpolate invalid emoji' do
        raw   = '# Chapter 1 :not_emoji:'
        markdown = '<h1>Chapter 1 :not_emoji:</h1>'

        EM.synchrony do
          drop = FakeContent.new 'http://cl.ly/hhgttg/chapter1.md'
          drop.stub! :raw => raw
          EM.stop

          drop.content.strip.should == markdown
        end
      end

      it 'does not interpolate emoji if emoji icons are missing' do
        Content::EmojiedHTML.any_instance.stub(has_emoji_images?: false)
        raw   = '# Chapter 1 :books:'
        markdown = '<h1>Chapter 1 :books:</h1>'

        EM.synchrony do
          drop = FakeContent.new 'http://cl.ly/hhgttg/chapter1.md'
          drop.stub! :raw => raw
          EM.stop

          drop.content.strip.should == markdown
        end
      end

    end

    it 'calls #super for non-markdown files' do
      drop = FakeContent.new 'http://cl.ly/hhgttg/chapter1.txt'
      drop.content.should == 'super content'
    end
  end

  describe '#markdown?' do
    %w( md mdown markdown ).each do |ext|
      it "is true when a #{ ext.upcase } file" do
        drop = FakeContent.new "http://cl.ly/hhgttg/cover.#{ ext }"
        drop.should be_markdown
      end
    end

    it 'is true when a markdown file with an upper case extension' do
      drop = FakeContent.new 'http://cl.ly/hhgttg/cover.MD'
      drop.should be_markdown
    end

    it 'is false when an image' do
      drop = FakeContent.new 'http://cl.ly/hhgttg/cover.png'
      drop.should_not be_markdown
    end

    it 'is false when pending' do
      drop = FakeContent.new nil
      drop.should_not be_markdown
    end
  end

end
