# First stage - Build the application
FROM node:20-alpine AS builder

WORKDIR /app/medusa

# Copy everything into the container
COPY . .

# Remove node_modules to avoid conflicts with host modules
RUN rm -rf node_modules

# Native module build toolchain
RUN apk add --no-cache python3 make g++

# Install dependencies while suppressing unnecessary logs
RUN npm install --loglevel=error
# Pin webpack for @medusajs/admin-ui ProgressPlugin compatibility
RUN npm install webpack@5.88.2 --save-dev --loglevel=error

# Build the application
RUN npm run build

# Second stage - Setup runtime environment
FROM node:20-alpine

WORKDIR /app/medusa

# Create dist folder
RUN mkdir dist

# Copy necessary config files
COPY package*.json ./
COPY medusa-config.js .

# Native module build toolchain (needed for npm install)
RUN apk add --no-cache python3 make g++

# Install Medusa CLI globally
RUN npm install -g @medusajs/medusa-cli

# Install production dependencies only
RUN npm install --omit=dev

# Copy the built files from the builder stage
COPY --from=builder /app/medusa/dist ./dist

# Expose the port your app will run on
EXPOSE 9000

# Start the application
ENTRYPOINT ["npm", "run", "start"]
