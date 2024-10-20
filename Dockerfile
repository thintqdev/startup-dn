# Stage 1: Build
FROM node:18-alpine AS build

# Install build dependencies
RUN apk update && apk add --no-cache \
    build-base \
    gcc \
    autoconf \
    automake \
    zlib-dev \
    libpng-dev \
    vips-dev \
    git

# Set environment variable for production
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# Set working directory
WORKDIR /opt/

# Copy package files
COPY package.json package-lock.json ./

# Install node-gyp globally and production dependencies
RUN npm install -g node-gyp && \
    npm config set fetch-retry-maxtimeout 600000 && \
    npm install --only=production

# Set PATH for npm binaries
ENV PATH=/opt/node_modules/.bin:$PATH

# Copy application files and build
WORKDIR /opt/app
COPY . .
RUN npm run build

# Stage 2: Production image
FROM node:18-alpine

# Install only the runtime dependencies
RUN apk add --no-cache vips-dev

# Set environment variable for production
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# Set working directory
WORKDIR /opt/

# Copy node_modules and built application from build stage
COPY --from=build /opt/node_modules ./node_modules
COPY --from=build /opt/app ./

# Ensure the /opt/app directory exists
RUN mkdir -p /opt/app && \
    chown -R node:node /opt/app

# Change ownership and set user
USER node

# Expose the application port
EXPOSE 1337

# Command to run the application
CMD ["npm", "run", "start"]
