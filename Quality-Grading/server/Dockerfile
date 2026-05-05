FROM node:18-alpine

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm install

# Copy application code and model
COPY . .

EXPOSE 3000

CMD ["npm", "start"]
