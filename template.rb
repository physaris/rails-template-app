#coding:utf-8


run "rm README.rdoc"

# 使用国内镜像
gsub_file "Gemfile", /https:\/\/rubygems.org/, "http://ruby.taobao.org"

# 一些基本GEM
gem 'rails-i18n'
gem 'devise'
gem 'activeadmin', github: 'gregbell/active_admin'
gem 'rolify'
gem 'cancan'

#gem 'anjlab-bootstrap-rails', '~> 3.0.0.3', :require => 'bootstrap-rails'
gem 'simple_form'

gem_group :development do
  gem 'hirb-unicode'
end

# 优先从本地安装
run "bundle install --local"

# 设置时区，编码
application "config.time_zone = 'Asia/Shanghai'"
application "config.i18n.default_locale = 'zh-CN'"
application "config.encoding = 'utf-8'"

# 本地化翻译文件
run "rm config/locales/en.yml"
run "cp #{File.dirname(__FILE__)}/zh-CN.yml config/locales/"

# 安装devise，并生成本地VIEW COPY
generate "devise:install"
generate "devise:views"

# 注销时的BUG？
gsub_file "config/initializers/devise.rb", /config.sign_out_via\ =\ :delete/, "config.sign_out_via = :delete, :get"

# 建立用户MODEL
generate "devise User"

# 后台安装，并且跳过生成Admin User
generate "active_admin:install User --skip-users"

=begin
run "mv app/assets/stylesheets/application.css app/assets/stylesheets/application.css.scss"
inject_into_file 'app/assets/stylesheets/application.css.scss', after: " */" do <<-'CSS'

@import "twitter/bootstrap";
CSS
end
=end

# 将后台资源移至vendor目录以避免样式表冲突
run "mv app/assets/stylesheets/active_admin.css.scss vendor/assets/stylesheets"
run "mv app/assets/javascripts/active_admin.js.coffee vendor/assets/javascripts"

# 复制devise本地化翻译
run "rm config/locales/devise.en.yml"
run "cp #{File.dirname(__FILE__)}/devise.zh-CN.yml config/locales/"

# 安装rolify
generate "rolify:role Role User"

# 安装cancan
generate "cancan:ability"


# 后台识别管理员方法
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

# 生成默认首页
generate "controller", "welcome index --skip-javascripts --skip-stylesheets --skip-helper"
gsub_file "config/routes.rb", /get\ "welcome\/index"/, "root to: 'welcome#index'"

#rake "db:migrate"

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
