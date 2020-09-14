Jekyll::Hooks.register :site, :pre_render do |site|
    posts = site.posts
    all_existing_tags = Dir.entries("_site_tags")
      .map { |t| t.match(/(.*).md/) }
      .compact.map { |m| m[1] }
  
    for post in posts.docs
        tags = post['tags'].reject { |t| t.empty? }
        tags.each do |tag|
            generate_tag_file(tag) if !all_existing_tags.include?(tag)
        end
    end
  end
  
  def generate_tag_file(tag)
    File.open("_site_tags/#{tag}.md", "wb") do |file|
      file << "---\nlayout: tag\ntitle: #{tag}\ntag: #{tag}\n---\n"
    end
  end
