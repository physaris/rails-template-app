u = User.new
u.email = "physaris@163.com"
u.password=12345678
u.password_confirmation=12345678
u.save

u.add_role :admin
