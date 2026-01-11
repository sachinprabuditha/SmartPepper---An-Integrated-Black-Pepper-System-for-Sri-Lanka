# SmartPepper: An Integrated Black Pepper System for Sri Lanka

![Project Banner](https://img.shields.io/badge/Project-25--26j--501-blue)
![Status](https://img.shields.io/badge/Status-In%20Development-yellow)
![License](https://img.shields.io/badge/License-MIT-green)

## 📋 Project Overview

**SmartPepper** is a comprehensive, technology-driven solution designed to revolutionize Sri Lanka's black pepper industry by addressing critical challenges in disease detection, quality grading, market access, and supply chain transparency.

### Project Details

- **Project Code**: 25-26j-501
- **Institution**: Sri Lanka Institute of Information Technology (SLIIT)
- **Supervisor**: Ms. Hansi de Silva
- **Co-supervisor**: Ms. Ishara Weerathunga
- **Academic Year**: 2025-2026

## 👥 Team Members

| ID         | Name              | Specialization       | Component                                       |
| ---------- | ----------------- | -------------------- | ----------------------------------------------- |
| IT22589286 | Lahiru J W A N    | Software Engineering | Disease Detection & Severity Analysis System    |
| IT22588500 | Premasiri J G P L | Software Engineering | IoT-Enabled Automated Grading System            |
| IT22583178 | Liyanage S K R    | Software Engineering | Price Prediction & Plantation Management System |
| IT22594686 | Prabuditha K. S   | Software Engineering | Blockchain-Based Auction System                 |

## 🎯 Problem Statement

_"Sri Lanka's Pepper industry is experiencing challenges due to global market changes and environmental factors. How can the industry adapt to remain competitive and sustainable?"_

### Key Challenges

1. **Biosafety Risks**

   - Diseases like Leaf Fall or Foot Rot often go undetected until catastrophic crop loss occurs
   - Lack of early warning systems for disease spread

2. **Subjective Grading**

   - Manual quality assessment leads to disputes and unfair compensation
   - Inconsistent grading outcomes due to human judgment

3. **Economic Volatility**

   - Farmers lack access to real-time market prices
   - High-quality yields often sold at suboptimal prices

4. **Supply Chain Opacity**
   - No standardized digital record for traceability
   - Difficulty meeting modern sustainability and transparency standards

## 🎓 Target Audience

### Primary: Smallholder Pepper Farmers

SmartPepper supports smallholder pepper farmers by providing AI-based disease detection, fair and objective quality grading, access to price predictions, and farming guidance. The system helps farmers make better decisions, reduce crop losses, and sell their produce at fair market prices.

### Secondary: Pepper Traders and Auctioneers

Benefits from a transparent, data-backed digital auction system where pepper quality is verified using AI and IoT technologies. This reduces procurement risks, improves trust, and streamlines the buying process.

### Tertiary: Agricultural Institutions and Policy Makers

The system aggregates industry data to provide valuable intelligence for monitoring crop health, market trends, and regional risks, enabling informed policy decisions and timely interventions.

## 🔬 Component 1: Disease Detection & Severity Analysis System

**Developer**: IT22589286 | Lahiru J W A N

### Overview

An all-in-one AI mobile app that provides automated, location-aware disease detection, severity estimation, remedy recommendations, and disease spread forecasting for black pepper plants.

### Key Features

- **Multi-Class Disease Detection**: Identifies healthy leaves, foot rot, pollu disease, and slow decline
- **Severity Analysis**: Predicts disease severity with confidence levels
- **Geolocation Mapping**: Records and visualizes healthy and infected plant locations on Google Maps
- **Spread Forecasting**: Estimates disease spread timelines based on severity
- **Remedy Suggestions**: Provides severity-based treatment recommendations

### Technical Stack

- **Framework**: Flutter (Mobile)
- **ML Model**: TensorFlow/PyTorch for image classification
- **Database**: MongoDB for detection records
- **APIs**: Google Maps API for geolocation

### Functional Requirements

- Image recognition from camera captures or gallery uploads
- Multi-class support for 4 distinct plant states
- Severity prediction with confidence levels
- GPS-based geolocation tracking
- Spread forecasting and remedy suggestion engine

### Non-Functional Requirements

- **High Accuracy**: Minimizing false negatives to prevent crop loss
- **Reliability**: Robust preprocessing for varied lighting and backgrounds
- **Scalability**: Capable of storing thousands of detection records

### Current Status

✅ Collected thousands of high-resolution images of pepper leaves  
✅ Implemented frontend and backend basic configuration  
✅ Trained classification model with high accuracy

### Future Implementations

- [ ] Increase dataset size and improve model accuracy
- [ ] Integrate GPS location capturing system
- [ ] Implement spread forecasting algorithm
- [ ] Complete remedy suggestion system

---

## ⚙️ Component 2: IoT-Enabled Automated Grading System

**Developer**: IT22588500 | Premasiri J G P L

### Overview

A low-cost, IoT-enabled, real-time black pepper grading system that combines physical density measurement and visual quality assessment to meet international export standards.

### Key Features

- **Automated Gram-Liter Test**: Load cell-based density measurement
- **Computer Vision Analysis**: ML-based evaluation of color, size, and surface quality
- **Integrated Grading**: Fuses density and visual data for objective quality scores
- **Web-Based Interface**: Real-time monitoring and control
- **Data Storage**: Historical grading records for analysis

### Technical Stack

- **Hardware**: Arduino, Load Cell, Camera Module, Conveyor System
- **ML Framework**: TensorFlow/PyTorch for visual classification
- **Backend**: Node.js with Wi-Fi connectivity
- **Web Interface**: Real-time dashboard for monitoring

### Functional Requirements

- Automatically measure density using Gram-Liter method
- Capture pepper images with controlled lighting
- Analyze quality (color, surface defects) using machine learning
- Integrate density and visual results for final grade
- Display outputs through web-based UI
- Store grading data for future reference

### Non-Functional Requirements

- **Low-Cost**: Affordable for smallholder farmers
- **Scalability**: Handle different sample volumes
- **High Accuracy**: Consistent and reliable grading
- **User-Friendly**: Minimal technical knowledge required
- **Maintainability**: Modular design for easy maintenance

### Current Status

✅ Designed and implemented prototype conveyor system  
✅ Developed load cell-based density measurement prototype  
✅ Successfully controlled conveyor via web application over Wi-Fi  
✅ Collected dataset of black pepper images  
✅ Trained ML model to classify pepper as Pure, Molded, or Discolored  
✅ Achieved successful grading results with single pepper images

### Future Implementations

- [ ] Mount camera modules directly onto conveyor system
- [ ] Implement controlled lighting setup
- [ ] Design automatic transfer mechanism from load cell to conveyor
- [ ] Enhance ML model for multi-seed image processing
- [ ] Improve real-time processing performance
- [ ] Integrate into fully automated end-to-end workflow

---

## 📊 Component 3: Price Prediction & Plantation Management System

**Developer**: IT22583178 | Liyanage S K R

### Overview

An intelligent system that provides black pepper price predictions, yield valuation, seasonal data analytics, and a domain-specific AI chat assistant to support farmer decision-making.

### Key Features

- **Price Prediction**: ML-based forecasting of black pepper market prices
- **Yield Valuation**: Harvest quantity estimation and valuation
- **Seasonal Analytics**: Trend analysis and data visualization
- **RAG-Based Chatbot**: Retrieval-Augmented Generation AI for agronomy guidance
- **Real-Time Data Collection**: Bluetooth scale integration for harvest data
- **Offline Support**: Works without continuous internet connectivity
- **Multi-Language**: Supports Sinhala, Tamil, and English

### Technical Stack

- **ML Framework**: Scikit-learn/TensorFlow for price prediction
- **NLP/RAG**: LangChain/Llama for chatbot development
- **Database**: MongoDB for seasonal data storage
- **Hardware**: Bluetooth-enabled weighing scales
- **Frontend**: Flutter (Mobile)

### Functional Requirements

- Price and yield prediction modules
- Seasonal data storage and trend analytics
- RAG-based agronomy chatbot
- Agronomy guidance module
- Real-time yield data collection via Bluetooth scales
- Plantation management interface

### Non-Functional Requirements

- **Performance**: Fast page loads, predictions, and chat responses
- **Scalability**: Support increasing numbers of users and data inputs
- **Usability**: Simple interface for non-technical users
- **Safety**: Prevent unverified agronomy advice generation
- **Explainability**: Display knowledge sources for chat responses

### Current Status

✅ Collected price dataset from Export Agriculture Department  
✅ Trained price prediction model  
✅ Implemented agronomy guidance module  
✅ Implemented plantation module  
✅ Implemented seasonal data collection module  
✅ Implemented price prediction module  
✅ Implemented RAG-based AI chat assistant

### Future Implementations

- [ ] Implement seasonal data analyzing module
- [ ] Continuous learning and knowledge base updates
- [ ] Integrate Bluetooth scale for real-time harvest data
- [ ] Expand multi-language support

---

## 🔗 Component 4: Blockchain-Based Auction System

**Developer**: IT22594686 | Prabuditha K. S

### Overview

A decentralized, transparent auction platform for pepper trading using Ethereum smart contracts, NFT-based digital passports, and IPFS for document storage.

### Key Features

- **Smart Contract Auctions**: Transparent, automated bidding on Ethereum
- **NFT Digital Passports**: Immutable records for each pepper lot
- **IPFS Storage**: Decentralized storage for certificates and images
- **Real-Time Bidding**: Live auction updates under 200ms latency
- **Traceability**: Complete supply chain transparency
- **Multi-User Interfaces**: Dedicated dashboards for farmers, exporters, and admins

### Technical Stack

- **Blockchain**: Ethereum (Hardhat test environment)
- **Smart Contracts**: Solidity
- **Storage**: IPFS for decentralized file storage
- **Backend**: Node.js with Web3.js
- **Frontend**: Flutter (Mobile), Next.js (Web)
- **Deployment**: Docker containers

### Functional Requirements

- Farmer registration and authentication
- Pepper lot creation with metadata and document upload
- NFT minting for each pepper lot
- Auction creation and scheduling
- Real-time bid placement and updates
- Automatic winner selection and NFT transfer
- Traceability view of pepper lot history
- IPFS-based storage for certificates and images

### Non-Functional Requirements

- **High Availability**: Fault-tolerant system design
- **Low Latency**: Bid updates under 200 milliseconds
- **Security**: Secure smart contract execution
- **Immutability**: Blockchain-based data integrity
- **Scalability**: Support concurrent auctions
- **Gas Efficiency**: Optimized blockchain transactions
- **Cross-Platform**: Works across devices and browsers

### Current Status

✅ Farmer mobile application (complete)  
✅ Exporter web dashboard (partial)  
✅ Admin dashboard (partial)  
✅ Pepper lot creation interface  
✅ IPFS document upload with preview  
✅ Live auction monitoring screen  
✅ Real-time bid updates  
✅ Auction history dashboard  
✅ NFT collection and ownership view  
✅ Traceability verification page  
✅ Deployed on Hardhat test blockchain environment  
✅ Docker containerization complete

### Future Implementations

- [ ] Sinhala and Tamil language support
- [ ] Smart contract-based payment escrow system
- [ ] Exporter mobile application
- [ ] Advanced analytics and price forecasting integration
- [ ] Quality analytics integration
- [ ] Performance optimization and load balancing

---

## 💼 Commercialization & Sustainability

### Freemium Model for Farmers

- **Free Core Features**: Disease detection, basic grading results, price viewing
- **Premium Services**: Advanced analytics, disease forecasting, export-grade quality reports, historical trends (subscription-based)

### Enterprise & Exporter Licensing

- Exporters, auction houses, and large-scale buyers pay for access to:
  - Verified grading data
  - Blockchain traceability
  - Auction dashboards
  - Analytics tools

### Institutional Partnerships

- Collaboration with government agencies, cooperatives, and agricultural institutions for:
  - Data access and monitoring tools
  - Decision support systems
  - Policy formulation support

---

## 🤝 Contributing

This is an academic research project. For collaboration inquiries, please contact the team members or supervisors.

---

## 📧 Contact

For inquiries about this research project:

- **Supervisor**: Ms. Hansi de Silva
- **Co-supervisor**: Ms. Ishara Weerathunga

**Team Members**:

- Lahiru J W A N (IT22589286) - Disease Detection System
- Premasiri J G P L (IT22588500) - IoT Grading System
- Liyanage S K R (IT22583178) - Price Prediction & Management
- Prabuditha K. S (IT22594686) - Blockchain Auction System

---

## 🙏 Acknowledgments

- Export Agriculture Department of Sri Lanka for price data
- Pepper farmers who provided domain expertise and feedback
- SLIIT Faculty of Computing for research support

---

**© 2025-2026 SmartPepper Research Team | SLIIT**
