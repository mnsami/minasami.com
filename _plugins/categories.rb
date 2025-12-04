module CategoriesPlugin
    class CategoriesGenerator < Jekyll::Generator
        safe true

        def generate(site)
            site.categories.each do |category, posts|
                site.pages << PostCategoryPage.new(site, site.source, category, posts)
            end
        end
    end

    class PostCategoryPage < Jekyll::Page
        def initialize(site, base, category, posts)
            @site = site
            @base = base
            @dir  = File.join('categories', category)
            @name = "index.html"

            self.process(@name)
            self.read_yaml(File.join(base, '_layouts'), 'category.html')

            # Format category name for display (e.g., "web-development" -> "Web Development")
            display_name = category.split('-').map(&:capitalize).join(' ')
            post_count = posts.length

            # SEO-optimized title
            self.data['category'] = category
            self.data['title'] = "#{display_name} Articles"

            # SEO meta description
            self.data['description'] = "Browse #{post_count} #{post_count == 1 ? 'article' : 'articles'} about #{display_name}. Expert tutorials, guides, and insights."

            # Additional SEO metadata
            self.data['category_display_name'] = display_name
            self.data['post_count'] = post_count
            self.data['posts'] = posts.sort_by { |post| post.date }.reverse

            # Canonical URL
            self.data['canonical_url'] = File.join(site.config['url'] || '', @dir)

            # Open Graph metadata
            self.data['og_type'] = 'website'
            self.data['og_title'] = "#{display_name} Articles | #{site.config['title']}"
            self.data['og_description'] = self.data['description']

            # Robots meta
            self.data['robots'] = 'index, follow'
        end
    end
end
