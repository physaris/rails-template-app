run "rm README.rdoc"

gsub_file "Gemfile", /https:\/\/rubygems.org/, "http://ruby.taobao.org"

gem 'rails-i18n'
gem 'devise'
gem 'activeadmin', github: 'gregbell/active_admin', branch: 'rails4'
gem 'rolify'
gem 'cancan'

gem 'bootstrap-sass'
gem 'bootswatch-rails'

gem_group :development do
  gem 'hirb-unicode'
end


run "bundle install --local"

application "config.time_zone = 'Asia/Shanghai'"
application "config.i18n.default_locale = 'zh-CN'"
application "config.encoding = 'utf-8'"

run "rm config/locales/en.yml"
run "cp #{File.dirname(__FILE__)}/zh-CN.yml config/locales/"

generate "devise:install"
gsub_file "config/initializers/devise.rb", /config.sign_out_via\ =\ :delete/, "config.sign_out_via = :delete, :get"

generate "devise User"
generate "active_admin:install User --skip-users"

run "mv app/assets/stylesheets/active_admin.css.scss vendor/assets/stylesheets"
run "mv app/assets/javascripts/active_admin.js.coffee vendor/assets/javascripts"

run "rm config/locales/devise.en.yml"
run "cp #{File.dirname(__FILE__)}/devise.zh-CN.yml config/locales/"

generate "rolify:role Role User"
generate "cancan:ability"

gsub_file "config/initializers/active_admin.rb", /config.authentication_method\ =\ :authenticate_user!/, 
  "config.authentication_method = :authenticate_admin_user!"
gsub_file "config/initializers/active_admin.rb", /config.current_user_method\ =\ :current_user/, 
  "config.current_user_method = :current_admin_user"

inject_into_file 'app/controllers/application_controller.rb', after: "protect_from_forgery with: :exception" do <<-'RUBY'

  def authenticate_admin_user!
    authenticate_user!
    unless current_user.has_role?(:admin)
      flash[:alert] = "This area is restricted to administrators only."
      redirect_to root_path
    end
  end
   
  def current_admin_user
    return nil if user_signed_in? && !current_user.has_role?(:admin)
    current_user
  end
RUBY
end

generate "controller", "welcome index --skip-javascripts --skip-stylesheets --skip-helper"
gsub_file "config/routes.rb", /get\ "welcome\/index"/, "root to: 'welcome#index'"

rake "db:migrate"

=begin
git :init
git :add => '.'
git :commit => "-a -m 'initial commit'"
=end
=begin
gem 'carrierwave'
gem 'spreadsheet'
gem 'animate-rails'
gem 'rabl'
gem 'oj'

gem_group :development do
  gem 'better_errors'
  gem 'meta_request'
  gem 'hirb-unicode'
  gem 'binding_of_caller'
  gem 'rack-mini-profiler'
  gem 'bullet'
end
=end
