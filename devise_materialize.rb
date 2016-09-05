run "pgrep spring | xargs kill -9"
run "rm Gemfile"
file 'Gemfile', <<-RUBY
source 'https://rubygems.org'
ruby '#{RUBY_VERSION}'

gem 'rails', '#{Rails.version}'
gem 'puma'
gem 'pg'
gem 'figaro'
gem 'jbuilder', '~> 2.0'
gem 'devise'#{Rails.version >= "5" ? ", github: 'plataformatec/devise'" : nil}
gem 'redis'
gem 'jquery-rails'
gem 'jquery-ui-rails', '~> 5.0', '>= 5.0.5'
gem 'uglifier'
gem 'materialize-sass'
gem 'font-awesome-sass'
gem 'simple_form'#{Rails.version >= "5" ? ", github: 'plataformatec/simple_form'" : nil}
gem 'autoprefixer-rails'
gem 'simple_form-materialize'

gem 'activeadmin', '~> 1.0.0.pre4'
gem 'inherited_resources', github: 'activeadmin/inherited_resources'
gem 'ransack',             github: 'activerecord-hackery/ransack'
gem 'draper',              '> 3.x'
gem 'sass-rails'

group :development, :test do
  gem 'binding_of_caller'
  gem 'better_errors'
  #{Rails.version >= "5" ? nil : "gem 'quiet_assets'"}
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'spring'
  #{Rails.version >= "5" ? "gem 'listen', '~> 3.0.5'" : nil}
  #{Rails.version >= "5" ? "gem 'spring-watcher-listen', '~> 2.0.0'" : nil}
end

group :production do
  gem 'rails_12factor'
end
RUBY

file ".ruby-version", RUBY_VERSION

file 'Procfile', <<-YAML
web: bundle exec puma -C config/puma.rb
YAML

if Rails.version < "5"
puma_file_content = <<-RUBY
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i

threads     threads_count, threads_count
port        ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "development" }
RUBY

file 'config/puma.rb', puma_file_content, force: true
end

run "touch 'config/initializers/simple_form_materialize-sass.rb'"
run "curl -L https://gist.githubusercontent.com/antoineayoub/a6de002da8d606999ff4f6d105798c79/raw/040b93e82b9f53e3c5a8c5156ff0b91e482ff907/gistfile1.txt > 'config/initializers/simple_form_materialize-sass.rb'"

run "rm -rf app/assets/stylesheets"
run "curl -L https://github.com/antoineayoub/rails-stylesheets/archive/master.zip > stylesheets.zip"
run "unzip stylesheets.zip -d app/assets && rm stylesheets.zip && mv app/assets/rails-stylesheets-master app/assets/stylesheets"

run 'rm app/assets/javascripts/application.js'
file 'app/assets/javascripts/application.js', <<-JS
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require materialize-sprockets
//= require_tree .
JS

gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

run 'rm app/views/layouts/application.html.erb'
file 'app/views/layouts/application.html.erb', <<-HTML
<!DOCTYPE html>
<html>
  <head>
    <title>TODO</title>
    <%= csrf_meta_tags %>
    #{Rails.version >= "5" ? "<%= action_cable_meta_tag %>" : nil}
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
    <%= stylesheet_link_tag    'application', media: 'all' %>
  </head>
  <body>
    <%= render 'shared/navbar' %>
    <%= render 'shared/flashes' %>
    <%= yield %>
    <%= javascript_include_tag 'application' %>
  </body>
</html>
HTML

file 'app/views/shared/_flashes.html.erb', <<-HTML
<% if notice %>
  <div class="alert alert-info alert-dismissible" role="alert">
    <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
    <%= notice %>
  </div>
<% end %>
<% if alert %>
  <div class="alert alert-warning alert-dismissible" role="alert">
    <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
    <%= alert %>
  </div>
<% end %>
HTML

run "curl -L https://raw.githubusercontent.com/lewagon/awesome-navbars/master/templates/_navbar_wagon.html.erb > app/views/shared/_navbar.html.erb"

run "rm README.rdoc"
markdown_file_content = <<-MARKDOWN
Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates)
MARKDOWN
file 'README.md', markdown_file_content, force: true

after_bundle do
  rake 'db:drop db:create db:migrate'
  generate(:controller, 'pages', 'home', '--no-helper', '--no-assets', '--skip-routes')
  route "root to: 'pages#home'"

  run "rm .gitignore"
  file '.gitignore', <<-TXT
.bundle
log/*.log
tmp/**/*
tmp/*
*.swp
.DS_Store
public/assets
TXT
  run "bin/figaro install"
  generate('devise:install')
  generate('devise', 'User')
  rake 'db:migrate'
  generate('devise:views')
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit with devise materialize template from https://github.com/antoineayoub/rails-templates' }
end
