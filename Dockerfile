# First stage - Build the application
FROM node:20.5.0 AS builder

WORKDIR /app/medusa

# Copy everything into the container
COPY . . 

# Remove node_modules to avoid conflicts with host modules
RUN rm -rf node_modules

# Update and install Python3
RUN apt-get update && apt-get install -y python3 python3-pip

# Install the latest npm and dependencies, while suppressing unnecessary logs
RUN npm install -g npm@latest
RUN npm install --loglevel=error

# Build the application
RUN npm run build

# Second stage - Setup runtime environment
FROM node:20.5.0

WORKDIR /app/medusa

# Create dist folder
RUN mkdir dist

# Copy necessary config files
COPY package*.json ./ 
COPY medusa-config.js .

# Update and install Python3 (if needed for your app)
RUN apt-get update && apt-get install -y python3 python3-pip

# Install Medusa CLI globally
RUN npm install -g @medusajs/medusa-cli

# Install production dependencies only (use package.json from the current stage)
RUN npm install --only=production

# Copy the built files from the builder stage
COPY --from=builder /app/medusa/dist ./dist

# Expose the port your app will run on
EXPOSE 9000

# Start the application
ENTRYPOINT ["npm", "run", "start"]
