#coding:utf-8

run "rm -f README.rdoc"
#run "rm -f public/index.html"

# 使用国内镜像
gsub_file "Gemfile", /https:\/\/rubygems.org/, "http://ruby.taobao.org"

# 一些基本GEM
gem 'rails-i18n'
gem 'devise'
gem 'jquery-ui-rails'
#gem 'activeadmin'
gem 'activeadmin', github: 'gregbell/active_admin'
gem 'rolify'
gem 'cancan'

gem 'simple_form'

gem_group :development do
  gem 'hirb-unicode'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'pry'
end

# 优先从本地安装
run "bundle install --local"

# 设置时区，编码
application "config.time_zone = 'Asia/Shanghai'"
application "config.i18n.default_locale = 'zh-CN'"
application "config.encoding = 'utf-8'"
application "I18n.config.enforce_available_locales = false"

# 本地化翻译文件
run "rm config/locales/en.yml"
run "cp #{File.dirname(__FILE__)}/zh-CN.yml config/locales/"

generate "simple_form:install"

# TODO: config/locales/simple_form.en.yml

# 安装devise，并生成本地VIEW COPY
generate "devise:install"
generate "devise:views"

# 注销时的BUG？
gsub_file "config/initializers/devise.rb", /config.sign_out_via\ =\ :delete/, "config.sign_out_via = :delete, :get"

# 建立用户MODEL
generate "devise User"

# 后台安装，并且跳过生成Admin User
generate "active_admin:install User --skip-users"
gsub_file "config/initializers/active_admin.rb", /config.authentication_method\ =\ :authenticate_user!/, 
  "config.authentication_method = :authenticate_admin_user!"
gsub_file "config/initializers/active_admin.rb", /#\ config.site_title_link\ =\ \"\/\"/,
  "config.site_title_link = \"/\""

# 将后台资源移至vendor目录以避免样式表冲突
run "mv app/assets/javascripts/active_admin.js.coffee vendor/assets/javascripts"
run "mv app/assets/stylesheets/active_admin.css.scss vendor/assets/stylesheets"

# 修正active_admin 找不到jquery ui的问题
#run "cp #{File.dirname(__FILE__)}/active_admin.js vendor/assets/javascripts"

# js中包含jquery ui
inject_into_file 'app/assets/javascripts/application.js', after: "\/\/= require jquery_ujs" do <<-'CODE'

//= require jquery.ui.all
CODE
end

# css中包含jquery ui
inject_into_file 'app/assets/stylesheets/application.css', after: " *= require_self" do <<-'CODE'

 *= require jquery.ui.all
CODE
end

# 复制devise本地化翻译
run "rm config/locales/devise.en.yml"
run "cp #{File.dirname(__FILE__)}/devise.zh-CN.yml config/locales/"

# 安装rolify
generate "rolify:role Role User"

# 安装cancan
generate "cancan:ability"

generate "active_admin:resource User"
generate "active_admin:resource Role"

# 后台识别管理员方法
gsub_file "config/initializers/active_admin.rb", /config.authentication_method\ =\ :authenticate_user!/, 
  "config.authentication_method = :authenticate_admin_user!"

inject_into_file 'app/controllers/application_controller.rb', after: "protect_from_forgery with: :exception" do <<-'CODE'

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
CODE
end

# 生成默认首页
generate "controller", "welcome index --skip-javascripts --skip-stylesheets --skip-helper"
gsub_file "config/routes.rb", /get\ "welcome\/index"/, "root to: 'welcome#index'"

# 在layout中增加一些基本链接
inject_into_file 'app/views/layouts/application.html.erb', after: "<body>" do <<-'CODE'

  <%= link_to("首页", root_path) %> |
  <% if current_user %>
    <%= link_to("后台", admin_root_path) %> |
    <%= link_to('退出', destroy_user_session_path, :method => :delete) %> |
    <%= link_to('修改密码', edit_registration_path(:user)) %>
  <% else %>
    <%= link_to('注册', new_registration_path(:user)) %> |
    <%= link_to('登录', new_session_path(:user)) %>
  <% end %>
  <br />
CODE
end

rake "db:migrate"

git :init
git :add => '.'
git :commit => "-a -m 'initial commit'"
