# Use Ruby 3.4 as base image
FROM ruby:3.4-alpine

# Install system dependencies
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    git \
    nodejs \
    npm \
    tzdata \
    yaml-dev

# Set working directory
WORKDIR /app

# Set environment variables
ENV RAILS_LOG_TO_STDOUT=1

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

# Copy the application code
COPY . .

# Precompile assets
RUN RAILS_ENV=production SECRET_KEY_BASE=dummy bundle exec rails assets:precompile

# Create a non-root user
RUN addgroup -g 1000 -S app && \
    adduser -u 1000 -S app -G app

# Change ownership of the app directory
RUN chown -R app:app /app
USER app

# Expose port 3000
EXPOSE 3000

# Start the Rails server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]