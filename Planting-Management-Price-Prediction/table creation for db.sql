-- 1. MASTER TABLES (Independent Data)
CREATE TABLE Users (
    Id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    Email VARCHAR(255) UNIQUE NOT NULL,
    PasswordHash TEXT NOT NULL,
    FullName VARCHAR(255) NOT NULL,
    PhoneNumber VARCHAR(20),
    CreatedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE Districts (
    Id SERIAL PRIMARY KEY,
    Name VARCHAR(100) UNIQUE NOT NULL
);
CREATE TABLE SoilTypes (
    Id SERIAL PRIMARY KEY,
    TypeName VARCHAR(100) UNIQUE NOT NULL
);
CREATE TABLE DistrictSoils (
    Id SERIAL PRIMARY KEY,
    DistrictId INTEGER REFERENCES Districts(Id) ON DELETE CASCADE,
    SoilTypeId INTEGER REFERENCES SoilTypes(Id) ON DELETE CASCADE,
    UNIQUE(DistrictId, SoilTypeId) -- Prevents duplicate links
);
-- Variety IDs remain VARCHAR because they are semantic keys (e.g., 'var_kuching')
CREATE TABLE PepperVarieties (
    Id VARCHAR(50) PRIMARY KEY, 
    Name VARCHAR(100) NOT NULL,
    Specialities TEXT,
    SuitabilityReason TEXT,
    SoilTypeRecommendation TEXT,
    SpacingMeters VARCHAR(50),
    VinesPerHectare INTEGER,
    PitDimensionsCm VARCHAR(50)
);

-- 2. KNOWLEDGE BASE
CREATE TABLE AgronomyGuides (
    Id SERIAL PRIMARY KEY,
    DistrictId INTEGER REFERENCES Districts(Id) ON DELETE CASCADE,
    SoilTypeId INTEGER REFERENCES SoilTypes(Id) ON DELETE CASCADE,
    VarietyId VARCHAR(50) REFERENCES PepperVarieties(Id) ON DELETE CASCADE,
    UNIQUE(DistrictId, SoilTypeId, VarietyId)
);

CREATE TABLE GuideSteps (
    Id SERIAL PRIMARY KEY,
    GuideId INTEGER REFERENCES AgronomyGuides(Id) ON DELETE CASCADE,
    StepNumber INTEGER NOT NULL,
    Title VARCHAR(255),
    Details TEXT
);

CREATE TABLE AgronomyTemplates (
    Id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    TaskName VARCHAR(255) NOT NULL,
    Phase VARCHAR(50),
    TimingMonthsAfterStarting INTEGER,
    InstructionalDetails TEXT,
    TaskType VARCHAR(50),
    VarietyKey VARCHAR(50) -- Links to PepperVarieties.Id
);

CREATE TABLE EmergencyTemplates (
    Id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    IssueName VARCHAR(255),
    Symptoms TEXT,
    TreatmentTask VARCHAR(255),
    Priority VARCHAR(20),
    Instructions TEXT
);

-- 3. PLANTATION & OPERATIONS
CREATE TABLE Farms (
    Id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    UserId UUID REFERENCES Users(Id) ON DELETE CASCADE, -- Must match Users.Id type
    FarmName VARCHAR(255) NOT NULL,
    DistrictId INTEGER REFERENCES Districts(Id),
    SoilTypeId INTEGER REFERENCES SoilTypes(Id),
    ChosenVarietyId VARCHAR(50) REFERENCES PepperVarieties(Id),
    FarmStartDate TIMESTAMP WITH TIME ZONE,
    AreaHectares NUMERIC,
    TotalVines INTEGER,
    CreatedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE FarmTasks (
    Id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    FarmId UUID REFERENCES Farms(Id) ON DELETE CASCADE, -- Must match Farms.Id type
    TaskName VARCHAR(255) NOT NULL,
    Phase VARCHAR(50),
    TaskType VARCHAR(50),
    VarietyKey VARCHAR(50),
    DueDate TIMESTAMP WITH TIME ZONE,
    Status VARCHAR(20),
    DateCompleted TIMESTAMP WITH TIME ZONE,
    InputDetails JSONB,
    DetailedSteps JSONB,
    ReasonWhy TEXT,
    IsManual BOOLEAN DEFAULT FALSE,
    Priority VARCHAR(20),
    CreatedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. HARVEST TRACKING
CREATE TABLE HarvestSeasons (
    Id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    FarmId UUID REFERENCES Farms(Id) ON DELETE CASCADE,
    SeasonName VARCHAR(100),
    StartMonth INTEGER,
    StartYear INTEGER,
    EndMonth INTEGER,
    EndYear INTEGER,
    CreatedBy UUID REFERENCES Users(Id)
);

CREATE TABLE HarvestSessions (
    Id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    SeasonId UUID REFERENCES HarvestSeasons(Id) ON DELETE CASCADE,
    SessionName VARCHAR(255),
    Date TIMESTAMP WITH TIME ZONE,
    YieldKg NUMERIC,
    AreaHarvested NUMERIC,
    Notes TEXT
);

-- 5. PERFORMANCE INDEXES
CREATE INDEX idx_farmtasks_farmid ON FarmTasks(FarmId);
CREATE INDEX idx_farms_userid ON Farms(UserId);
CREATE INDEX idx_guides_filtering ON AgronomyGuides(DistrictId, SoilTypeId, VarietyId);

CREATE TABLE PepperKnowledge (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Classification
    category TEXT NOT NULL, 
    sub_category TEXT,

    -- Location & Variety
    district TEXT,             -- NULL = applies to all districts
    variety TEXT,              -- NULL = applies to all varieties

    -- Plant age (months)
    plant_age_min INT,         -- NULL = any age
    plant_age_max INT,         -- NULL = any age

    -- Seasonality
    month_start INT,           -- 1–12, NULL if not seasonal
    month_end INT,             -- 1–12, NULL if not seasonal

    -- Core content
    title TEXT NOT NULL,
    content TEXT NOT NULL,

    -- Metadata
    source TEXT,               -- DOA / research station
    confidence_level TEXT,     -- high / medium

    -- Vector embedding
    embedding VECTOR(1536),

    created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_pepper_category ON PepperKnowledge(category);
CREATE INDEX idx_pepper_district ON PepperKnowledge(district);
CREATE INDEX idx_pepper_variety ON PepperKnowledge(variety);

CREATE INDEX idx_pepper_embedding ON PepperKnowledge
USING ivfflat (embedding vector_l2_ops);

CREATE EXTENSION vector;

