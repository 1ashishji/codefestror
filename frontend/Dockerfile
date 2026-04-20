FROM node:20-slim

WORKDIR /app

# Install dependencies first for better caching
COPY package*.json ./
RUN npm install

# Copy the rest of the application
COPY . .

EXPOSE 5173

# Start the Vite development server
CMD ["npm", "run", "dev"]
