# Store — Rails Practice Project

A Ruby on Rails e-commerce practice application with Products, Categories, and Shops.

---

## Table of Contents

1. [Project Setup](#project-setup)
2. [Devise — Authentication](#1-devise--authentication)
3. [Rolify — Role Management](#2-rolify--role-management)
4. [CanCanCan — Authorization](#3-cancancan--authorization)
5. [Paranoia — Soft Delete](#4-paranoia--soft-delete)
6. [PaperTrail — Audit / Version History](#5-papertrail--audit--version-history)
7. [Putting It All Together](#putting-it-all-together)

---

## Project Setup

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/dev
```

---

## 1. Devise — Authentication

Devise handles user sign-up, login, logout, and session management.

### Installation

```ruby
# Gemfile
gem "devise"
```

```bash
bundle install
bin/rails generate devise:install
```

Follow the post-install instructions printed in the terminal (set `default_url_options`, add flash messages to your layout, etc.).

### Generate the User model

```bash
bin/rails generate devise User
bin/rails db:migrate
```

This creates a `users` table with email, encrypted password, and token columns.

### Protect controllers

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
end
```

Allow public access on specific actions:

```ruby
# app/controllers/home_controller.rb
class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
end
```

### Views

Generate editable Devise views (optional):

```bash
bin/rails generate devise:views
```

### Helpers in views

```erb
<% if user_signed_in? %>
  Signed in as <%= current_user.email %>
  <%= link_to "Sign out", destroy_user_session_path, data: { turbo_method: :delete } %>
<% else %>
  <%= link_to "Sign in", new_user_session_path %>
<% end %>
```

### Key helpers

| Helper | Description |
|---|---|
| `current_user` | The currently signed-in user |
| `user_signed_in?` | Returns `true` if a user is logged in |
| `authenticate_user!` | Before-action that redirects guests |

---

## 2. Rolify — Role Management

Rolify adds a flexible, database-backed role system to your User model.

### Installation

```ruby
# Gemfile
gem "rolify"
```

```bash
bundle install
bin/rails generate rolify Role User
bin/rails db:migrate
```

This creates a `roles` table and a `users_roles` join table.

### Add `rolify` to User

```ruby
# app/models/user.rb
class User < ApplicationRecord
  rolify
  # devise modules...
end
```

### Assign and check roles

```ruby
# Assign a global role
user.add_role :admin

# Assign a resource-scoped role (e.g. manager of a specific shop)
user.add_role :manager, shop

# Check roles
user.has_role? :admin           # => true / false
user.has_role? :manager, shop   # => true / false

# Remove a role
user.remove_role :admin
```

### Seed initial admin

```ruby
# db/seeds.rb
admin = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.password = "password"
end
admin.add_role :admin unless admin.has_role?(:admin)
```

---

## 3. CanCanCan — Authorization

CanCanCan defines what each role is allowed to do via an `Ability` class.

### Installation

```ruby
# Gemfile
gem "cancancan"
```

```bash
bundle install
bin/rails generate cancan:ability
```

### Define abilities

```ruby
# app/models/ability.rb
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new  # guest user (not logged in)

    if user.has_role? :admin
      can :manage, :all  # admins can do everything
    elsif user.has_role? :manager
      can :manage, Shop
      can :read, Product
      can :read, Category
    else
      # Regular authenticated users
      can :read, Product
      can :read, Category
      can :read, Shop
    end
  end
end
```

### Check abilities in controllers

```ruby
# app/controllers/products_controller.rb
class ProductsController < ApplicationController
  load_and_authorize_resource  # auto-loads @product and checks ability

  def index
    # @products already loaded by load_and_authorize_resource
  end

  def destroy
    @product.destroy
    redirect_to products_path
  end
end
```

### Check abilities in views

```erb
<% if can? :destroy, @product %>
  <%= link_to "Delete", product_path(@product), data: { turbo_method: :delete } %>
<% end %>

<% if can? :create, Product %>
  <%= link_to "New Product", new_product_path %>
<% end %>
```

### Handle unauthorized access

```ruby
# app/controllers/application_controller.rb
rescue_from CanCan::AccessDenied do |exception|
  redirect_to root_path, alert: exception.message
end
```

---

## 4. Paranoia — Soft Delete

Paranoia replaces hard deletes with a `deleted_at` timestamp, keeping records in the database for recovery and audit purposes.

### Installation

```ruby
# Gemfile
gem "paranoia"
```

```bash
bundle install
```

### Add `deleted_at` column to a model

```bash
bin/rails generate migration AddDeletedAtToProducts deleted_at:datetime:index
bin/rails generate migration AddDeletedAtToShops    deleted_at:datetime:index
bin/rails db:migrate
```

### Enable soft delete on a model

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  acts_as_paranoid

  validates :name, presence: true
  belongs_to :category, optional: true
  has_many :shop_products, dependent: :destroy
  has_many :shops, through: :shop_products
end
```

### Usage

```ruby
product = Product.find(1)

# Soft-delete (sets deleted_at, does NOT remove the row)
product.destroy

# Default scope automatically excludes soft-deleted records
Product.all          # only non-deleted products

# Include soft-deleted records
Product.with_deleted

# Only soft-deleted records
Product.only_deleted

# Restore a soft-deleted record
product.restore
product.restore!(recursive: true)  # also restores dependent records

# Permanently delete
product.really_destroy!
```

### Paranoia with CanCanCan

CanCanCan's `load_and_authorize_resource` respects the default scope, so soft-deleted records are automatically hidden from regular queries.

---

## 5. PaperTrail — Audit / Version History

PaperTrail records every create, update, and destroy event so you can see who changed what and when, and roll back to any previous state.

### Installation

```ruby
# Gemfile
gem "paper_trail"
```

```bash
bundle install
bin/rails generate paper_trail:install
bin/rails db:migrate
```

This creates a `versions` table.

### Enable versioning on a model

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  has_paper_trail

  acts_as_paranoid           # combine with soft delete
  validates :name, presence: true
  belongs_to :category, optional: true
  has_many :shop_products, dependent: :destroy
  has_many :shops, through: :shop_products
end
```

### Record the current user

Tell PaperTrail who made the change by setting `whodunnit` in `ApplicationController`:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_paper_trail_whodunnit

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
  end
end
```

`set_paper_trail_whodunnit` is provided by PaperTrail and automatically stores `current_user.id` in the `versions.whodunnit` column.

### Querying versions

```ruby
product = Product.find(1)

# All versions for this record
product.versions

# Who last changed it
product.versions.last.whodunnit

# What changed (returns a hash of { attr => [old, new] })
product.versions.last.changeset

# Revert to the previous version
previous = product.versions[-2].reify
previous.save!
```

### View version history in a view

```erb
<%# app/views/products/show.html.erb %>
<h3>Change History</h3>
<table>
  <thead>
    <tr><th>Version</th><th>Event</th><th>Changed by</th><th>At</th></tr>
  </thead>
  <tbody>
    <% @product.versions.reverse.each do |v| %>
      <tr>
        <td><%= v.index %></td>
        <td><%= v.event %></td>
        <td><%= User.find_by(id: v.whodunnit)&.email || "system" %></td>
        <td><%= v.created_at.strftime("%Y-%m-%d %H:%M") %></td>
      </tr>
    <% end %>
  </tbody>
</table>
```

---

## Putting It All Together

### Full Gemfile additions

```ruby
gem "devise"
gem "rolify"
gem "cancancan"
gem "paranoia"
gem "paper_trail"
```

### Recommended model setup (Product example)

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  has_paper_trail        # track all changes
  acts_as_paranoid       # soft delete instead of hard delete

  validates :name, presence: true
  belongs_to :category, optional: true
  has_many :shop_products, dependent: :destroy
  has_many :shops, through: :shop_products
end
```

### Recommended ApplicationController setup

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!           # Devise
  before_action :set_paper_trail_whodunnit    # PaperTrail

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
  end
end
```

### Role-based flow summary

```
Request
  └─ authenticate_user!       (Devise)   → redirect to login if not signed in
       └─ load_and_authorize_resource    (CanCanCan) → check role via Ability
            └─ Ability#initialize
                 └─ user.has_role?(:admin)  (Rolify) → grant/deny access
                      └─ Product#destroy    (Paranoia) → sets deleted_at
                           └─ version saved (PaperTrail) → records whodunnit
```

### Quick reference

| Gem | Purpose | Key method/macro |
|---|---|---|
| Devise | Authentication | `authenticate_user!`, `current_user` |
| Rolify | Role management | `add_role`, `has_role?` |
| CanCanCan | Authorization | `can`, `load_and_authorize_resource` |
| Paranoia | Soft delete | `acts_as_paranoid`, `restore` |
| PaperTrail | Audit trail | `has_paper_trail`, `versions` |

