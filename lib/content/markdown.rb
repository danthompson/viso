require 'em-synchrony'
require 'metriks'
require 'redcarpet'
require 'emoji'

class Content
  module Markdown
    def content
      return super unless markdown?
      Metriks.timer('markdown').time {
        # Both EM::Synchrony.defer and #raw call Fiber.yield so they can't be
        # nested. Download content outside the .defer block.
        downloaded = raw

        EM::Synchrony.defer {

          emojied = EmojiedHTML.new(downloaded).render

          Redcarpet::Markdown.
            new(PygmentizedHTML, fenced_code_blocks: true).
            render(emojied)
        }
      }
    end

    def markdown?
      %w( .md
          .mdown
          .markdown ).include? extension
    end

  private

    def extension
      @url and File.extname(@url).downcase
    end
  end

  class EmojiedHTML

    def initialize(content)
      @content = content
    end

    def has_emoji_images?
      File.directory? 'public/images/emoji'
    end

    def render
      if has_emoji_images?
        @content.gsub(/:([a-z0-9\+\-_]+):/) do |match|
          if Emoji.names.include?($1)
            emoji_image_tag($1)
          else
            match
          end
        end
      else
        @content
      end
    end

    def emoji_image_tag(name)
      %{<img alt="#{ name }" src="images/emoji/#{ name }.png" width="20" height="20" class="emoji" />}
    end

  end

  # TODO: This is just a spike.
  class PygmentizedHTML < Redcarpet::Render::HTML
    def block_code(code, language)
      Content::Code.highlight code, language
    end
  end
end
