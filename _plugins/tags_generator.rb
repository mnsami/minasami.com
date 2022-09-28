module PostTagsPlugin
    class PostTagsGenerator < Jekyll::Generator
        safe true

        def generate(site)
            site.tags.each do |tag, posts|
                site.pages << PostTagPage.new(site, site.source, tag)
            end
        end
    end

    class PostTagPage < Jekyll::Page
        def initialize(site, base, tag)
            @site = site
            @base = base
            @dir  = File.join('tags', tag)
            @name = "index.html"

            self.process(@name)
            self.read_yaml(File.join(base, '_layouts'), 'tag.html')
            self.data['tag'] = tag
            self.data['title'] = "Tag: #{tag}"
        end
    end
end
