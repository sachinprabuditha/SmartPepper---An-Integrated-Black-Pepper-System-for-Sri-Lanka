FROM node:18

# Install Python and OpenCV dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Set up Python virtual environment and install dependencies
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir ultralytics opencv-python-headless numpy

# Install Node.js dependencies
COPY package*.json ./
RUN npm install

# Copy application code
COPY . .

EXPOSE 5000

CMD ["npm", "start"]
