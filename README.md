# 🛒 Store — Rails Practice Project

A Ruby on Rails e-commerce practice app with Products, Categories, and Shops.  
UI: **Tailwind CSS** · blue/white theme · `rounded-2xl` cards.

---

## Table of Contents

1. [Project Setup](#project-setup)
2. [Gems](#gems)
   - [Devise — Authentication](#1-devise--authentication)
   - [Rolify — Roles](#2-rolify--roles)
   - [CanCanCan — Authorization](#3-cancancan--authorization)
   - [Paranoia — Soft Delete](#4-paranoia--soft-delete)
   - [PaperTrail — Audit Log](#5-papertrail--audit-log)
3. [API — Products CRUD](#6-api-tutorial--products-crud)

---

## Project Setup

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/dev
```

---

## Gems

---

## 1. Devise — Authentication

### Install

```ruby
# Gemfile
gem "devise"
```

```bash
bundle install
bin/rails generate devise:install
bin/rails generate devise User
bin/rails db:migrate
```

### Required config

```ruby
# config/environments/development.rb
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
```

### Protect the app

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
end
```

Allow the home page to be public:

```ruby
# app/controllers/home_controller.rb
class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
end
```

### Devise views — styled to match the system UI

Generate the views first:

```bash
bin/rails generate devise:views
```

Then replace `app/views/devise/sessions/new.html.erb` with:

```erb
<div class="min-h-screen flex items-center justify-center bg-blue-50">
  <div class="bg-white rounded-2xl shadow-md p-8 w-full max-w-md">
    <h1 class="text-3xl font-bold text-blue-700 mb-6 text-center">Sign In</h1>

    <%= form_for(resource, as: resource_name, url: session_path(resource_name)) do |f| %>
      <div class="mb-4">
        <%= f.label :email, class: "block text-sm font-medium text-gray-700 mb-1" %>
        <%= f.email_field :email, autofocus: true, autocomplete: "email",
              class: "w-full border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" %>
      </div>

      <div class="mb-6">
        <%= f.label :password, class: "block text-sm font-medium text-gray-700 mb-1" %>
        <%= f.password_field :password, autocomplete: "current-password",
              class: "w-full border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" %>
      </div>

      <div class="mb-4 flex items-center gap-2">
        <%= f.check_box :remember_me, class: "rounded" %>
        <%= f.label :remember_me, class: "text-sm text-gray-600" %>
      </div>

      <%= f.submit "Sign In",
            class: "w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 rounded-lg transition cursor-pointer" %>
    <% end %>

    <div class="mt-6 text-center text-sm text-gray-500 space-y-1">
      <%= link_to "Forgot your password?", new_user_password_path, class: "text-blue-600 hover:underline" %>
      <br>
      <%= link_to "Create account", new_user_registration_path, class: "text-blue-600 hover:underline" %>
    </div>
  </div>
</div>
```

Replace `app/views/devise/registrations/new.html.erb` with:

```erb
<div class="min-h-screen flex items-center justify-center bg-blue-50">
  <div class="bg-white rounded-2xl shadow-md p-8 w-full max-w-md">
    <h1 class="text-3xl font-bold text-blue-700 mb-6 text-center">Create Account</h1>

    <%= form_for(resource, as: resource_name, url: registration_path(resource_name)) do |f| %>
      <% resource.errors.full_messages.each do |msg| %>
        <div class="mb-4 text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg px-4 py-2"><%= msg %></div>
      <% end %>

      <div class="mb-4">
        <%= f.label :email, class: "block text-sm font-medium text-gray-700 mb-1" %>
        <%= f.email_field :email, autofocus: true, autocomplete: "email",
              class: "w-full border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" %>
      </div>

      <div class="mb-4">
        <%= f.label :password, class: "block text-sm font-medium text-gray-700 mb-1" %>
        <%= f.password_field :password, autocomplete: "new-password",
              class: "w-full border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" %>
      </div>

      <div class="mb-6">
        <%= f.label :password_confirmation, class: "block text-sm font-medium text-gray-700 mb-1" %>
        <%= f.password_field :password_confirmation, autocomplete: "new-password",
              class: "w-full border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" %>
      </div>

      <%= f.submit "Create Account",
            class: "w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 rounded-lg transition cursor-pointer" %>
    <% end %>

    <div class="mt-6 text-center text-sm">
      <%= link_to "Already have an account? Sign in", new_user_session_path, class: "text-blue-600 hover:underline" %>
    </div>
  </div>
</div>
```

### Nav bar — add auth links to the layout

```erb
<%# app/views/layouts/application.html.erb — inside <nav> %>
<ul class="flex gap-6 items-center">
  <li><a href="/" class="text-blue-100 hover:text-white font-medium transition">Home</a></li>
  <li><a href="/products" class="text-blue-100 hover:text-white font-medium transition">Products</a></li>
  <li><a href="/categories" class="text-blue-100 hover:text-white font-medium transition">Categories</a></li>
  <li><a href="/shops" class="text-blue-100 hover:text-white font-medium transition">Shops</a></li>

  <% if user_signed_in? %>
    <li class="text-blue-200 text-sm"><%= current_user.email %></li>
    <li><%= button_to "Sign out", destroy_user_session_path,
            method: :delete,
            class: "bg-white text-blue-700 font-semibold px-4 py-1.5 rounded-lg hover:bg-blue-100 transition text-sm cursor-pointer border-none" %></li>
  <% else %>
    <li><%= link_to "Sign in", new_user_session_path,
          class: "bg-white text-blue-700 font-semibold px-4 py-1.5 rounded-lg hover:bg-blue-100 transition text-sm" %></li>
  <% end %>
</ul>
```

### Key helpers

| Helper | What it does |
|---|---|
| `current_user` | Returns the signed-in `User` object (or `nil`) |
| `user_signed_in?` | `true` when someone is logged in |
| `authenticate_user!` | Redirects guests to `/users/sign_in` |

---

## 2. Rolify — Roles

### Install

```ruby
# Gemfile
gem "rolify"
```

```bash
bundle install
bin/rails generate rolify Role User
bin/rails db:migrate
```

### Add `rolify` to User

```ruby
# app/models/user.rb
class User < ApplicationRecord
  rolify
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
```

### Assign the admin role

```ruby
# In Rails console or db/seeds.rb
user = User.find_by(email: "admin@example.com")
user.add_role :admin
```

### Check the role

```ruby
user.has_role? :admin   # => true
user.has_role? :admin   # => false  (for a regular user)
```

### Seed an admin user

```ruby
# db/seeds.rb
admin = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
end
admin.add_role :admin unless admin.has_role?(:admin)
```

```bash
bin/rails db:seed
```

---

## 3. CanCanCan — Authorization

### Install

```ruby
# Gemfile
gem "cancancan"
```

```bash
bundle install
bin/rails generate cancan:ability
```

### Ability: admin can do everything, everyone else read-only

```ruby
# app/models/ability.rb
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new   # guest (not logged in)

    if user.has_role? :admin
      can :manage, :all   # full access to everything
    else
      # logged-in users without a role: read only
      can :read, Product
      can :read, Category
      can :read, Shop
    end
  end
end
```

### Protect controllers with one line

```ruby
# app/controllers/products_controller.rb
class ProductsController < ApplicationController
  load_and_authorize_resource param_method: :product_param   # loads @product / @products and checks ability

  def index; end
  def show; end
  def new; end
  def edit; end

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

### Handle access denied

```ruby
# app/controllers/application_controller.rb
rescue_from CanCan::AccessDenied do |exception|
  redirect_to root_path, alert: "You are not authorized to do that."
end
```

### Hide buttons in views based on ability

```erb
<% if can? :create, Product %>
  <%= link_to "+ New Product", new_product_path,
        class: "bg-blue-600 hover:bg-blue-700 text-white font-semibold px-5 py-2 rounded-lg transition" %>
<% end %>

<% @products.each do |product| %>
  <%= product.name %>
  <% if can? :update, product %>
    <%= link_to "Edit", edit_product_path(product), class: "text-sm text-yellow-600 hover:underline" %>
  <% end %>
  <% if can? :destroy, product %>
    <%= button_to "Delete", product_path(product), method: :delete,
          data: { turbo_confirm: "Are you sure?" },
          class: "text-sm text-red-600 hover:underline bg-transparent border-none cursor-pointer" %>
  <% end %>
<% end %>
```

---

## 4. Paranoia — Soft Delete

Instead of deleting a row, Paranoia sets `deleted_at` and hides the record from normal queries.

### Install

```ruby
# Gemfile
gem "paranoia"
```

```bash
bundle install
bin/rails generate migration AddDeletedAtToProducts deleted_at:datetime:index
bin/rails db:migrate
```

### Enable on the model

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

product.destroy        # sets deleted_at — NOT removed from DB
product.deleted?       # => true

Product.all            # automatically excludes soft-deleted records
Product.with_deleted   # includes soft-deleted records
Product.only_deleted   # only soft-deleted records

product.restore        # clears deleted_at — record is visible again
product.really_destroy! # permanent DELETE
```

### Restore route (optional)

```ruby
# config/routes.rb
resources :products do
  member { patch :restore }
end
```

```ruby
# app/controllers/products_controller.rb
def destroy
  @product.destroy
  redirect_to products_path, notice: "Product moved to trash."
end

def restore
  @product = Product.only_deleted.find(params[:id])
  @product.restore!
  redirect_to products_path, notice: "Product restored."
end
```

---

## 5. PaperTrail — Audit Log

PaperTrail saves a version row every time a record is created, updated, or destroyed.

### Install

```ruby
# Gemfile
gem "paper_trail"
```

```bash
bundle install
bin/rails generate paper_trail:install
bin/rails db:migrate
```

### Enable on the model

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  has_paper_trail
  acts_as_paranoid

  validates :name, presence: true
  belongs_to :category, optional: true
  has_many :shop_products, dependent: :destroy
  has_many :shops, through: :shop_products
end
```

### Record who made the change

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_paper_trail_whodunnit   # stores current_user.id automatically

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: "You are not authorized to do that."
  end
end
```

### Query versions

```ruby
product = Product.find(1)

product.versions                       # all versions (oldest first)
product.versions.last.event            # "create" / "update" / "destroy"
product.versions.last.whodunnit        # user id who made the change
product.versions.last.changeset        # { "name" => ["Old", "New"] }

# Rebuild the record as it was before the last change
old = product.versions[-2].reify
old.name    # previous name (not saved)
old.save!   # rollback to that state
```

### Show history in a view

```erb
<%# app/views/products/show.html.erb %>
<div class="bg-white rounded-2xl shadow-md p-8 mt-6">
  <h2 class="text-xl font-bold text-blue-700 mb-4">Change History</h2>
  <table class="w-full text-sm">
    <thead class="bg-blue-50 text-blue-700">
      <tr>
        <th class="p-2 text-left">Event</th>
        <th class="p-2 text-left">Changed by</th>
        <th class="p-2 text-left">When</th>
      </tr>
    </thead>
    <tbody class="divide-y divide-blue-100">
      <% @product.versions.reverse.each do |v| %>
        <tr>
          <td class="p-2 capitalize"><%= v.event %></td>
          <td class="p-2"><%= User.find_by(id: v.whodunnit)&.email || "system" %></td>
          <td class="p-2 text-gray-500"><%= v.created_at.strftime("%Y-%m-%d %H:%M") %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

---

## Quick Reference

| Gem | Install command | Key macro / method |
|---|---|---|
| Devise | `rails g devise User` | `authenticate_user!`, `current_user` |
| Rolify | `rails g rolify Role User` | `add_role`, `has_role?` |
| CanCanCan | `rails g cancan:ability` | `can`, `load_and_authorize_resource`, `can?` |
| Paranoia | add `deleted_at` migration | `acts_as_paranoid`, `restore`, `only_deleted` |
| PaperTrail | `rails g paper_trail:install` | `has_paper_trail`, `versions`, `reify` |

---

## 6. API Tutorial — Products CRUD

A versioned JSON API (`/api/v1/products`) with no extra gems — pure Rails.

---

### Step 1 — Add routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root "home#index"
  resources :products
  resources :categories
  resources :shops

  namespace :api do
    namespace :v1 do
      resources :products, only: [:index, :show, :create, :update, :destroy]
    end
  end
end
```

---

### Step 2 — Create the base API controller

```ruby
# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ActionController::API
    end
  end
end
```

Inheriting from `ActionController::API` instead of `ActionController::Base` strips out browser-only middleware (sessions, cookies, CSRF protection) — suitable for a JSON API.

---

### Step 3 — Create the products controller skeleton

```ruby
# app/controllers/api/v1/products_controller.rb
module Api
  module V1
    class ProductsController < BaseController
      before_action :set_product, only: [:show, :update, :destroy]

      private

      def set_product
        @product = Product.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Product not found" }, status: :not_found
      end

      def product_params
        params.require(:product).permit(:name, :category_id)
      end
    end
  end
end
```

`before_action :set_product` runs before `show`, `update`, and `destroy` so `@product` is always available in those actions.

---

### Step 4 — GET /api/v1/products (index)

Return all products as JSON.

```ruby
# GET /api/v1/products
def index
  @products = Product.all
  render json: @products, status: :ok
end
```

**curl**
```bash
curl http://localhost:3000/api/v1/products
```

**Response** `200 OK`
```json
[
  { "id": 1, "name": "Widget", "category_id": 1, "created_at": "...", "updated_at": "..." },
  { "id": 2, "name": "Gadget", "category_id": 2, "created_at": "...", "updated_at": "..." }
]
```

---

### Step 5 — GET /api/v1/products/:id (show)

Return a single product by id.

```ruby
# GET /api/v1/products/:id
def show
  render json: @product, status: :ok
end
```

**curl**
```bash
curl http://localhost:3000/api/v1/products/1
```

**Response** `200 OK`
```json
{ "id": 1, "name": "Widget", "category_id": 1, "created_at": "...", "updated_at": "..." }
```

**Not found** `404 Not Found`
```json
{ "error": "Product not found" }
```

---

### Step 6 — POST /api/v1/products (create)

Create a new product. Returns `201 Created` on success or `422` with error messages on failure.

```ruby
# POST /api/v1/products
def create
  @product = Product.new(product_params)
  if @product.save
    render json: @product, status: :created
  else
    render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
  end
end
```

**curl**
```bash
curl -X POST http://localhost:3000/api/v1/products \
  -H "Content-Type: application/json" \
  -d '{"product": {"name": "Widget", "category_id": 1}}'
```

**Response** `201 Created`
```json
{ "id": 3, "name": "Widget", "category_id": 1, "created_at": "...", "updated_at": "..." }
```

**Validation failure** `422 Unprocessable Entity`
```json
{ "errors": ["Name can't be blank"] }
```

---

### Step 7 — PATCH /api/v1/products/:id (update)

Update an existing product. Returns the updated record or `422` on failure.

```ruby
# PATCH/PUT /api/v1/products/:id
def update
  if @product.update(product_params)
    render json: @product, status: :ok
  else
    render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
  end
end
```

**curl**
```bash
curl -X PATCH http://localhost:3000/api/v1/products/1 \
  -H "Content-Type: application/json" \
  -d '{"product": {"name": "Updated Widget"}}'
```

**Response** `200 OK`
```json
{ "id": 1, "name": "Updated Widget", "category_id": 1, "created_at": "...", "updated_at": "..." }
```

---

### Step 8 — DELETE /api/v1/products/:id (destroy)

Delete a product. Returns `204 No Content` with an empty body.

```ruby
# DELETE /api/v1/products/:id
def destroy
  if @product.destroy
    render json: { message: "Product deleted successfully" }, status: :ok
  else
    render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
  end
end
```

**curl**
```bash
curl -X DELETE http://localhost:3000/api/v1/products/1
```

**Response** `204 No Content` *(empty body)*

---

### Complete controller (all steps combined)

```ruby
# app/controllers/api/v1/products_controller.rb
module Api
  module V1
    class ProductsController < BaseController
      before_action :set_product, only: [:show, :update, :destroy]

      def index
        @products = Product.all
        render json: @products, status: :ok
      end

      def show
        render json: @product, status: :ok
      end

      def create
        @product = Product.new(product_params)
        if @product.save
          render json: @product, status: :created
        else
          render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @product.update(product_params)
          render json: @product, status: :ok
        else
          render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @product.destroy
          render json: { message: "Product deleted successfully" }, status: :ok
        else
          render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_product
        @product = Product.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Product not found" }, status: :not_found
      end

      def product_params
        params.require(:product).permit(:name, :category_id)
      end
    end
  end
end
```

---

### Endpoint summary

| Step | Method | Path | Action | Success status |
|---|---|---|---|---|
| 4 | GET | `/api/v1/products` | List all products | `200 OK` |
| 5 | GET | `/api/v1/products/:id` | Show one product | `200 OK` |
| 6 | POST | `/api/v1/products` | Create a product | `201 Created` |
| 7 | PATCH/PUT | `/api/v1/products/:id` | Update a product | `200 OK` |
| 8 | DELETE | `/api/v1/products/:id` | Delete a product | `204 No Content` |

---
