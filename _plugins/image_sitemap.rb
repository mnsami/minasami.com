# frozen_string_literal: true

# Image Sitemap Generator for Jekyll
# Generates an XML sitemap with image references for better Google Image Search indexing
# Based on Google's Image Sitemap specification:
# https://developers.google.com/search/docs/advanced/sitemaps/image-sitemaps

module Jekyll
  # Image Sitemap Page
  class ImageSitemapPage < Page
    def initialize(site, images_data)
      @site = site
      @base = site.source
      @dir = '/'
      @name = 'sitemap-images.xml'

      process(@name)

      @data = {}
      @data['layout'] = nil
      @content = build_sitemap(images_data)
    end

    def build_sitemap(images_data)
      xml = []
      xml << '<?xml version="1.0" encoding="UTF-8"?>'
      xml << '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"'
      xml << '        xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">'

      images_data.each do |page_data|
        xml << '  <url>'
        xml << "    <loc>#{xml_escape(page_data[:url])}</loc>"

        page_data[:images].each do |img|
          xml << '    <image:image>'
          xml << "      <image:loc>#{xml_escape(img[:url])}</image:loc>"
          xml << "      <image:caption>#{xml_escape(img[:caption])}</image:caption>" if img[:caption]
          xml << "      <image:title>#{xml_escape(img[:title])}</image:title>" if img[:title]
          xml << '    </image:image>'
        end

        xml << '  </url>'
      end

      xml << '</urlset>'
      xml.join("\n")
    end

    def xml_escape(text)
      return '' if text.nil?
      text.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
          .gsub('"', '&quot;').gsub("'", '&apos;')
    end
  end

  # Image Sitemap Generator
  class ImageSitemapGenerator < Generator
    safe true
    priority :low

    # Image extensions to include in sitemap
    IMAGE_EXTENSIONS = %w[.jpg .jpeg .png .gif .webp .svg].freeze

    def generate(site)
      @site = site
      @config = site.config
      @base_url = @config['url'] || ''
      @image_count = 0

      # Collect images from all posts and pages
      images_data = collect_images_data

      # Create and add the sitemap page
      sitemap_page = ImageSitemapPage.new(site, images_data)
      site.pages << sitemap_page

      Jekyll.logger.info 'Image Sitemap:', "Generated sitemap-images.xml with #{@image_count} images"
    end

    private

    def collect_images_data
      data = []

      # Process all posts
      @site.posts.docs.each do |post|
        images = extract_images_from_content(post.content, post.data)
        next if images.empty?

        data << {
          url: @base_url + post.url,
          images: images
        }
      end

      # Process all pages (excluding asset pages)
      @site.pages.each do |page|
        next if page.url.start_with?('/assets/')
        next if page.url.end_with?('.xml')

        images = extract_images_from_content(page.content, page.data)
        next if images.empty?

        data << {
          url: @base_url + page.url,
          images: images
        }
      end

      data
    end

    def extract_images_from_content(content, front_matter)
      images = []
      return images if content.nil? || content.empty?

      # Extract images from featured image in front matter
      if front_matter['image']
        images << {
          url: absolute_url(front_matter['image']),
          title: front_matter['title'],
          caption: front_matter['description']
        }
      end

      # Extract images from markdown: ![alt](url)
      content.scan(/!\[([^\]]*)\]\(([^)]+)\)/).each do |alt, src|
        clean_src = clean_liquid_syntax(src)
        next unless image_file?(clean_src)
        images << {
          url: absolute_url(clean_src),
          caption: alt.to_s.strip.empty? ? nil : alt.strip,
          title: alt.to_s.strip.empty? ? nil : alt.strip
        }
        @image_count += 1
      end

      # Extract images from HTML: <img src="..." alt="...">
      content.scan(/<img[^>]+src=["']([^"']+)["'][^>]*(?:alt=["']([^"']+)["'])?[^>]*>/i).each do |src, alt|
        clean_src = clean_liquid_syntax(src)
        next unless image_file?(clean_src)
        next if images.any? { |img| img[:url] == absolute_url(clean_src) } # Avoid duplicates

        images << {
          url: absolute_url(clean_src),
          caption: alt.to_s.strip.empty? ? nil : alt.strip,
          title: alt.to_s.strip.empty? ? nil : alt.strip
        }
        @image_count += 1
      end

      images.uniq { |img| img[:url] }
    end

    def clean_liquid_syntax(path)
      path.to_s.gsub(/\{\{[^}]+\}\}/, '').gsub(/\{%[^%]+%\}/, '').strip
    end

    def image_file?(path)
      return false if path.nil? || path.empty?
      IMAGE_EXTENSIONS.any? { |ext| path.downcase.end_with?(ext) }
    end

    def absolute_url(path)
      return path if path.start_with?('http://', 'https://')

      clean_path = clean_liquid_syntax(path).sub(%r{^/}, '')
      "#{@base_url}/#{clean_path}"
    end
  end
end
