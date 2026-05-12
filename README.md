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

> **Gem versions used in this guide**
> | Gem | Tested version |
> |---|---|
> | devise | ~> 4.9 |
> | rolify | ~> 6.0 |
> | cancancan | ~> 3.6 |
> | paranoia | ~> 2.6 |
> | paper_trail | ~> 16.0 |


---

## Project Setup

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/dev
```

---

## 1. Devise — Authentication

Devise is a full-featured authentication solution for Rails built on Warden. It is composed of 10 modules — you only enable the ones you need.

| Module | Purpose |
|---|---|
| `database_authenticatable` | Stores & validates password |
| `registerable` | Users can sign up / edit / delete account |
| `recoverable` | Password reset via email |
| `rememberable` | "Remember me" cookie |
| `validatable` | Email & password validations |
| `confirmable` | Email confirmation before sign-in |
| `lockable` | Lock account after N failed attempts |
| `timeoutable` | Expire session after inactivity |
| `trackable` | Track sign-in count, timestamps, IP |
| `omniauthable` | OAuth support (GitHub, Google, etc.) |

### Installation

```ruby
# Gemfile
gem "devise"
```

```bash
bundle install
bin/rails generate devise:install
```

After running the generator, follow the instructions printed in the terminal. The two most important ones:

```ruby
# config/environments/development.rb  — set mailer host
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
```

```erb
<%# app/views/layouts/application.html.erb — add flash messages %>
<p class="notice"><%= notice %></p>
<p class="alert"><%= alert %></p>
```

### Generate the User model

```bash
bin/rails generate devise User
bin/rails db:migrate
```

This creates a migration that adds the `users` table with sensible defaults. By default the model includes:

```ruby
# app/models/user.rb (auto-generated)
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
```

### Add extra fields to the User model (e.g. name)

```bash
bin/rails generate migration AddNameToUsers name:string
bin/rails db:migrate
```

Then permit the new field through Devise's strong parameters in `ApplicationController`:

```ruby
# app/controllers/application_controller.rb
before_action :configure_permitted_parameters, if: :devise_controller?

protected

def configure_permitted_parameters
  devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  devise_parameter_sanitizer.permit(:account_update, keys: [:name])
end
```

### Protect controllers

Require login for **all** actions:

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

### Routes added by Devise

```
GET    /users/sign_up       → registrations#new
POST   /users               → registrations#create
GET    /users/sign_in       → sessions#new
POST   /users/sign_in       → sessions#create
DELETE /users/sign_out      → sessions#destroy
GET    /users/password/new  → passwords#new
POST   /users/password      → passwords#create (sends reset email)
```

### Customising redirect after sign-in / sign-out

```ruby
# app/controllers/application_controller.rb

# Where to go after successful login
def after_sign_in_path_for(resource)
  root_path
end

# Where to go after sign-out
def after_sign_out_path_for(resource_or_scope)
  new_user_session_path
end
```

### Generate and customise Devise views

```bash
bin/rails generate devise:views
```

This copies all Devise ERB templates into `app/views/devise/` so you can style them with Tailwind or any framework.

Key view files:
```
app/views/devise/sessions/new.html.erb        ← login form
app/views/devise/registrations/new.html.erb   ← sign-up form
app/views/devise/passwords/new.html.erb       ← forgot password form
```

### Helpers in views

```erb
<% if user_signed_in? %>
  Signed in as <%= current_user.email %>
  <%= link_to "Sign out", destroy_user_session_path, data: { turbo_method: :delete } %>
<% else %>
  <%= link_to "Sign in", new_user_session_path %>
  <%= link_to "Sign up", new_user_registration_path %>
<% end %>
```

### Key helpers

| Helper | Description |
|---|---|
| `current_user` | The currently signed-in `User` object (or `nil`) |
| `user_signed_in?` | Returns `true` if a user is logged in |
| `authenticate_user!` | Before-action — redirects guests to login |
| `sign_in(user)` | Programmatically sign in a user |
| `sign_out(user)` | Programmatically sign out a user |

### Common gotchas

- **Turbo / Rails 7+**: The sign-out link requires `data: { turbo_method: :delete }` because Devise uses `DELETE /users/sign_out` by default.
- **No root route**: If you see `No route matches [GET] "/"` after installing Devise, make sure `root "home#index"` is defined in `config/routes.rb` and that `HomeController` has a `skip_before_action :authenticate_user!` for the index action (or remove the global `before_action` if you don't need it there).
- **Confirmable**: If you enable the `confirmable` module, users must click the email link before they can sign in. In development, use `bin/rails console` → `User.last.confirm` to confirm manually.

---

## 2. Rolify — Role Management

Rolify adds a flexible, database-backed role system to your User model. Roles can be **global** (e.g. admin) or **resource-scoped** (e.g. manager of a specific Shop).

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

This creates two tables:

```
roles         → id, name, resource_type, resource_id, created_at, updated_at
users_roles   → user_id, role_id
```

### Add `rolify` to the User model

```ruby
# app/models/user.rb
class User < ApplicationRecord
  rolify          # ← add this line
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
```

Rolify adds a `before_create` callback that automatically gives every new user a default role if you configure one (optional).

### Add `resourcify` to models that can have scoped roles

```ruby
# app/models/shop.rb
class Shop < ApplicationRecord
  resourcify   # enables user.add_role :manager, shop
  has_many :shop_products, dependent: :destroy
  has_many :products, through: :shop_products
end
```

### Assigning roles

```ruby
user = User.find(1)

# Global role — applies everywhere
user.add_role :admin
user.add_role :editor

# Resource-scoped role — applies only to a specific record
shop = Shop.find(1)
user.add_role :manager, shop

# Resource-type role — applies to all records of a class
user.add_role :moderator, Shop
```

### Checking roles

```ruby
user.has_role? :admin               # global admin?
user.has_role? :manager, shop       # manager of this specific shop?
user.has_role? :moderator, Shop     # moderator of any shop?

# Check any of several roles
user.has_any_role? :admin, :editor

# Check all roles
user.has_all_roles? :admin, :editor
```

### Removing roles

```ruby
user.remove_role :editor
user.remove_role :manager, shop
```

### Querying users by role

```ruby
# All admins
User.with_role(:admin)

# All managers of a specific shop
User.with_role(:manager, shop)

# All roles for a user
user.roles                          # => ActiveRecord::Relation of Role objects
user.roles.pluck(:name)             # => ["admin", "editor"]
```

### Listing a user's roles in a view

```erb
<%# Somewhere in a user profile view %>
<strong>Roles:</strong>
<% current_user.roles.each do |role| %>
  <span class="badge"><%= role.name %></span>
<% end %>
```

### Seed initial roles

```ruby
# db/seeds.rb
admin = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
end
admin.add_role :admin unless admin.has_role?(:admin)

manager = User.find_or_create_by!(email: "manager@example.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
end
shop = Shop.first_or_create!(name: "Main Shop")
manager.add_role :manager, shop
```

### Common gotchas

- Rolify caches roles in memory. After changing roles in the console, reload the user object: `user.reload`.
- If you use `resourcify` on a model, make sure the `roles` table has the `resource_type` and `resource_id` columns (the generator handles this automatically).

---

## 3. CanCanCan — Authorization

CanCanCan separates *what a user can do* from *how the app works*. All permissions are defined in one place: the `Ability` class.

### Installation

```ruby
# Gemfile
gem "cancancan"
```

```bash
bundle install
bin/rails generate cancan:ability
```

This creates `app/models/ability.rb`.

### Understanding `can` and `cannot`

```ruby
can :action, Subject                     # simple rule
can :action, Subject, field: value       # rule with conditions (SQL WHERE)
can :action, Subject { |obj| obj.user == user }  # rule with block (in-memory)
cannot :action, Subject                  # explicit denial (overrides can)
```

**Actions**: `:read`, `:create`, `:update`, `:destroy`, `:manage` (all actions)  
**Subject**: a model class, `:all`, or a symbol

### Define abilities

```ruby
# app/models/ability.rb
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new  # guest (not logged in)

    if user.has_role? :admin
      # Admins can do everything
      can :manage, :all

    elsif user.has_role? :manager
      # Managers can fully manage shops and read everything else
      can :manage, Shop
      can :manage, ShopProduct
      can :read,   Product
      can :read,   Category

      # Managers can update products in their own shops only
      can :update, Product do |product|
        product.shops.any? { |shop| user.has_role?(:manager, shop) }
      end

    else
      # Regular users — read-only
      can :read, Product
      can :read, Category
      can :read, Shop
    end
  end
end
```

### `load_and_authorize_resource` in controllers

This single macro:
1. Loads the resource from the database into an instance variable.
2. Checks the current user's ability for the current action.
3. Raises `CanCan::AccessDenied` if not allowed.

```ruby
# app/controllers/products_controller.rb
class ProductsController < ApplicationController
  load_and_authorize_resource
  # @product is automatically loaded for member actions (show/edit/update/destroy)
  # @products is automatically loaded for collection actions (index)

  def index
    # @products is already set — no need to query manually
  end

  def show
    # @product is already set
  end

  def new
    # @product is already a new Product.new
  end

  def create
    if @product.save
      redirect_to @product, notice: "Product created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: "Product updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: "Product deleted."
  end

  private

  def product_params
    params.require(:product).permit(:name, :category_id)
  end
end
```

### Manual authorization (without the macro)

```ruby
# Authorize a specific object explicitly
authorize! :destroy, @product

# Check without raising an exception
if can? :destroy, @product
  # show delete button
end

# Fetch only records the user can read
@products = Product.accessible_by(current_ability, :read)
```

### Check abilities in views

```erb
<% if can? :create, Product %>
  <%= link_to "New Product", new_product_path, class: "btn" %>
<% end %>

<% @products.each do |product| %>
  <%= product.name %>
  <% if can? :update, product %>
    <%= link_to "Edit", edit_product_path(product) %>
  <% end %>
  <% if can? :destroy, product %>
    <%= link_to "Delete", product_path(product), data: { turbo_method: :delete } %>
  <% end %>
<% end %>
```

### Handle unauthorized access globally

```ruby
# app/controllers/application_controller.rb
rescue_from CanCan::AccessDenied do |exception|
  redirect_to root_path, alert: "Access denied: #{exception.message}"
end
```

### Testing abilities in the Rails console

```ruby
user = User.find_by(email: "admin@example.com")
ability = Ability.new(user)

ability.can? :destroy, Product        # => true (admin)
ability.can? :create, Shop            # => true (admin)

regular = User.find_by(email: "user@example.com")
ability2 = Ability.new(regular)
ability2.can? :destroy, Product       # => false (regular user)
ability2.can? :read, Product          # => true
```

---

## 4. Paranoia — Soft Delete

Paranoia overrides `destroy` to set a `deleted_at` timestamp rather than removing the row. Records are hidden by a default scope, but remain in the database for recovery.

### Installation

```ruby
# Gemfile
gem "paranoia"
```

```bash
bundle install
```

### Add `deleted_at` column to every model you want to soft-delete

```bash
bin/rails generate migration AddDeletedAtToProducts deleted_at:datetime:index
bin/rails generate migration AddDeletedAtToCategories deleted_at:datetime:index
bin/rails generate migration AddDeletedAtToShops deleted_at:datetime:index
bin/rails db:migrate
```

Migration preview:

```ruby
class AddDeletedAtToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :deleted_at, :datetime
    add_index  :products, :deleted_at
  end
end
```

### Enable soft delete on a model

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  acts_as_paranoid   # ← add this

  validates :name, presence: true
  belongs_to :category, optional: true
  has_many :shop_products, dependent: :destroy
  has_many :shops, through: :shop_products
end
```

### Core usage

```ruby
product = Product.find(1)

# ── Soft delete ──────────────────────────────────────────────
product.destroy          # sets deleted_at = Time.current
product.deleted?         # => true
product.deleted_at       # => 2026-05-13 10:00:00 UTC

# ── Default scope (excludes deleted) ─────────────────────────
Product.all              # WHERE deleted_at IS NULL
Product.count            # only non-deleted count

# ── Include deleted records ───────────────────────────────────
Product.with_deleted                     # all rows
Product.with_deleted.where(name: "TV")   # scoped query on all rows

# ── Only deleted records ──────────────────────────────────────
Product.only_deleted                     # WHERE deleted_at IS NOT NULL

# ── Restore ──────────────────────────────────────────────────
product.restore                          # clears deleted_at
product.restore!(recursive: true)        # also restores dependent records
Product.restore(1)                       # restore by id (class method)
Product.restore([1, 2, 3])               # restore multiple by ids

# ── Permanent delete ──────────────────────────────────────────
product.really_destroy!                  # actual DELETE FROM query
```

### Callbacks

Paranoia fires the standard ActiveRecord callbacks but also provides:

```ruby
class Product < ApplicationRecord
  acts_as_paranoid

  before_destroy  :log_deletion
  after_destroy   :notify_team
  after_restore   :reindex   # called after restore

  private

  def log_deletion
    Rails.logger.info "Product #{id} soft-deleted at #{Time.current}"
  end

  def notify_team
    # send Slack message, etc.
  end

  def reindex
    # update Elasticsearch / Meilisearch index
  end
end
```

### Soft delete in controllers

```ruby
# app/controllers/products_controller.rb
def destroy
  @product.destroy             # soft delete
  redirect_to products_path, notice: "Product moved to trash."
end

def restore
  @product = Product.only_deleted.find(params[:id])
  @product.restore!
  redirect_to products_path, notice: "Product restored."
end
```

Add a route for restore:

```ruby
# config/routes.rb
resources :products do
  member do
    patch :restore
  end
end
```

### Show a "Trash" page

```ruby
# app/controllers/products_controller.rb
def trash
  @deleted_products = Product.only_deleted.order(deleted_at: :desc)
end
```

```erb
<%# app/views/products/trash.html.erb %>
<h1>Trash</h1>
<% @deleted_products.each do |product| %>
  <div>
    <%= product.name %>
    <span>Deleted <%= time_ago_in_words(product.deleted_at) %> ago</span>
    <%= link_to "Restore", restore_product_path(product), data: { turbo_method: :patch } %>
    <%= link_to "Destroy permanently", product_path(product),
          data: { turbo_method: :delete, turbo_confirm: "This cannot be undone!" } %>
  </div>
<% end %>
```

### Associations and soft delete

When a parent is soft-deleted, `dependent: :destroy` will soft-delete children too if they also `acts_as_paranoid`. Use `dependent: :destroy` on the association:

```ruby
class Shop < ApplicationRecord
  acts_as_paranoid
  has_many :shop_products, dependent: :destroy
end
```

### Paranoia with CanCanCan

CanCanCan's `load_and_authorize_resource` respects Paranoia's default scope, so soft-deleted records are automatically invisible to normal queries. No extra configuration needed.

---

## 5. PaperTrail — Audit / Version History

PaperTrail records every `create`, `update`, and `destroy` event as a row in the `versions` table. You can see who changed what and when, diff any two states, or roll back to any previous version.

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

The generator creates the `versions` table:

```
id          bigint PK
item_type   string       ← model class name (e.g. "Product")
item_id     bigint       ← record id
event       string       ← "create", "update", or "destroy"
whodunnit   string       ← who made the change (stored as string)
object      text         ← serialised previous state (YAML/JSON)
object_changes text      ← serialised diff
created_at  datetime
```

### Enable versioning on a model

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  has_paper_trail   # ← add this

  acts_as_paranoid
  validates :name, presence: true
  belongs_to :category, optional: true
  has_many :shop_products, dependent: :destroy
  has_many :shops, through: :shop_products
end
```

You can also enable it selectively for categories and shops:

```ruby
# app/models/category.rb
class Category < ApplicationRecord
  has_paper_trail
  has_many :products
end
```

### Tell PaperTrail who made the change

PaperTrail provides `set_paper_trail_whodunnit` which reads `current_user` automatically:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_paper_trail_whodunnit  # ← stores current_user.id in whodunnit
end
```

By default `whodunnit` stores `current_user.id.to_s`. To store the email instead:

```ruby
# config/initializers/paper_trail.rb
PaperTrail.config.whodunnit_field = :email  # if you want a custom field

# OR override the method in ApplicationController:
def user_for_paper_trail
  user_signed_in? ? current_user.email : "guest"
end
```

### Querying versions

```ruby
product = Product.find(1)

# All versions (oldest first)
product.versions

# Latest version
product.versions.last

# Who last changed it
product.versions.last.whodunnit   # => "1" (user id as string)

# The event that was recorded
product.versions.last.event       # => "update"

# What changed
product.versions.last.changeset
# => { "name" => ["Old Name", "New Name"], "updated_at" => [...] }

# Reify — rebuild the object as it was at that version
old = product.versions[-2].reify  # second-to-last state
old.name                          # => "Old Name" (not saved to DB)
old.save!                         # rollback to that state
```

### Useful PaperTrail scopes & class methods

```ruby
# All versions for a specific user
PaperTrail::Version.where(whodunnit: current_user.id.to_s)

# All versions of a specific event type
PaperTrail::Version.where(event: "destroy")

# All recent changes across the whole app
PaperTrail::Version.order(created_at: :desc).limit(50)

# All changes to a model class
PaperTrail::Version.where(item_type: "Product").order(created_at: :desc)
```

### Ignoring specific attributes

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  has_paper_trail ignore: [:updated_at]
  # Only track meaningful changes, not every timestamp bump
end
```

Or track only specific attributes:

```ruby
has_paper_trail only: [:name, :category_id]
```

### Custom metadata

Attach extra data to every version:

```ruby
# app/controllers/application_controller.rb
before_action :set_paper_trail_whodunnit

def info_for_paper_trail
  { ip: request.remote_ip, user_agent: request.user_agent }
end
```

Add corresponding columns to the `versions` table:

```bash
bin/rails generate migration AddMetadataToVersions ip:string user_agent:string
bin/rails db:migrate
```

### View version history in a view

```erb
<%# app/views/products/show.html.erb %>
<h3>Change History</h3>
<div class="overflow-x-auto">
  <table class="w-full text-sm border">
    <thead class="bg-gray-100">
      <tr>
        <th class="p-2 text-left">#</th>
        <th class="p-2 text-left">Event</th>
        <th class="p-2 text-left">Changed by</th>
        <th class="p-2 text-left">What changed</th>
        <th class="p-2 text-left">When</th>
      </tr>
    </thead>
    <tbody>
      <% @product.versions.reverse.each do |v| %>
        <tr class="border-t">
          <td class="p-2"><%= v.index %></td>
          <td class="p-2"><span class="badge"><%= v.event %></span></td>
          <td class="p-2"><%= User.find_by(id: v.whodunnit)&.email || "system" %></td>
          <td class="p-2 text-xs text-gray-500">
            <% v.changeset.except("created_at", "updated_at").each do |attr, (from, to)| %>
              <div><strong><%= attr %></strong>: <%= from.inspect %> → <%= to.inspect %></div>
            <% end %>
          </td>
          <td class="p-2"><%= v.created_at.strftime("%Y-%m-%d %H:%M") %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

### Rollback a record in the controller

```ruby
# app/controllers/products_controller.rb
def rollback
  version = PaperTrail::Version.find(params[:version_id])
  @product = version.reify
  if @product.save
    redirect_to @product, notice: "Product rolled back to version #{version.index}."
  else
    redirect_to product_path(version.item_id), alert: "Rollback failed."
  end
end
```

Add the route:

```ruby
# config/routes.rb
resources :products do
  member do
    patch :rollback
    patch :restore
  end
end
```

### PaperTrail with Paranoia

When Paranoia soft-deletes a record, PaperTrail records a `"destroy"` event. When the record is restored, PaperTrail records an `"update"` event (it sets `deleted_at` back to `nil`). Both gems work together with no extra configuration.

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

```bash
bundle install

# Devise
bin/rails generate devise:install
bin/rails generate devise User
bin/rails db:migrate

# Rolify
bin/rails generate rolify Role User
bin/rails db:migrate

# CanCanCan
bin/rails generate cancan:ability

# PaperTrail
bin/rails generate paper_trail:install
bin/rails db:migrate

# Paranoia — manual migrations only
bin/rails generate migration AddDeletedAtToProducts deleted_at:datetime:index
bin/rails generate migration AddDeletedAtToCategories deleted_at:datetime:index
bin/rails generate migration AddDeletedAtToShops deleted_at:datetime:index
bin/rails db:migrate
```

### Recommended model setup

```ruby
# app/models/user.rb
class User < ApplicationRecord
  rolify
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end

# app/models/product.rb
class Product < ApplicationRecord
  has_paper_trail only: [:name, :category_id]
  acts_as_paranoid

  validates :name, presence: true
  belongs_to :category, optional: true
  has_many :shop_products, dependent: :destroy
  has_many :shops, through: :shop_products
end

# app/models/shop.rb
class Shop < ApplicationRecord
  resourcify
  has_paper_trail
  acts_as_paranoid
  has_many :shop_products, dependent: :destroy
  has_many :products, through: :shop_products
end

# app/models/category.rb
class Category < ApplicationRecord
  has_paper_trail
  acts_as_paranoid
  has_many :products
end
```

### Recommended ApplicationController setup

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!           # Devise
  before_action :set_paper_trail_whodunnit    # PaperTrail
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: "Access denied: #{exception.message}"
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def user_for_paper_trail
    user_signed_in? ? current_user.email : "guest"
  end

  def after_sign_in_path_for(_resource)
    root_path
  end
end
```

### Complete Ability class

```ruby
# app/models/ability.rb
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.has_role? :admin
      can :manage, :all

    elsif user.has_role? :manager
      can :manage, Shop
      can :manage, ShopProduct
      can :read,   [Product, Category]
      can :update, Product do |p|
        p.shops.any? { |s| user.has_role?(:manager, s) }
      end

    else
      can :read, [Product, Category, Shop]
    end
  end
end
```

### Role-based request flow

```
HTTP Request
  │
  ├─ authenticate_user!        (Devise)      → 302 to /users/sign_in if guest
  │
  ├─ set_paper_trail_whodunnit (PaperTrail)  → records current_user.email
  │
  ├─ load_and_authorize_resource (CanCanCan) → loads @product, checks Ability
  │       └─ Ability#initialize
  │               └─ user.has_role?(:admin)  (Rolify) → can :manage, :all?
  │
  ├─ Controller action runs
  │       └─ @product.destroy               (Paranoia)   → sets deleted_at
  │               └─ PaperTrail callback    (PaperTrail) → saves "destroy" version
  │
  └─ Response rendered
```

### Quick reference

| Gem | Purpose | Key methods |
|---|---|---|
| **Devise** | Authentication | `authenticate_user!`, `current_user`, `user_signed_in?`, `sign_in`, `sign_out` |
| **Rolify** | Role management | `add_role`, `remove_role`, `has_role?`, `has_any_role?`, `User.with_role` |
| **CanCanCan** | Authorization | `can`, `cannot`, `load_and_authorize_resource`, `can?`, `authorize!` |
| **Paranoia** | Soft delete | `acts_as_paranoid`, `destroy`, `restore`, `really_destroy!`, `with_deleted`, `only_deleted` |
| **PaperTrail** | Audit trail | `has_paper_trail`, `versions`, `reify`, `changeset`, `whodunnit` |

