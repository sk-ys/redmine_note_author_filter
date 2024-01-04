Dir[File.join(File.expand_path('../lib/note_author_filter/patches', __FILE__), '*.rb')].each do |patch|
  require_dependency patch
end

Redmine::Plugin.register :redmine_note_author_filter do
  name 'Redmine Note Author Filter plugin'
  author 'sk-ys'
  description 'This is a plugin for Redmine'
  version '0.1.1'
  url 'https://github.com/sk-ys/redmine_note_author_filter'
  author_url 'https://github.com/sk-ys'
end
