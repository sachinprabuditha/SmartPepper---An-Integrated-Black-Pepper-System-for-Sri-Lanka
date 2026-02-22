import { DataTypes } from 'sequelize';
import sequelize from '../config/db.js';

const PepperKnowledge = sequelize.define('PepperKnowledge', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        field: 'id'
    },
    category: {
        type: DataTypes.TEXT,
        allowNull: false,
        field: 'category'
    },
    subCategory: {
        type: DataTypes.TEXT,
        field: 'sub_category'
    },
    district: {
        type: DataTypes.TEXT,
        field: 'district'
    },
    variety: {
        type: DataTypes.TEXT,
        field: 'variety'
    },
    plantAgeMin: {
        type: DataTypes.INTEGER,
        field: 'plant_age_min'
    },
    plantAgeMax: {
        type: DataTypes.INTEGER,
        field: 'plant_age_max'
    },
    monthStart: {
        type: DataTypes.INTEGER,
        field: 'month_start'
    },
    monthEnd: {
        type: DataTypes.INTEGER,
        field: 'month_end'
    },
    title: {
        type: DataTypes.TEXT,
        allowNull: false,
        field: 'title'
    },
    content: {
        type: DataTypes.TEXT,
        allowNull: false,
        field: 'content'
    },
    source: {
        type: DataTypes.TEXT,
        field: 'source'
    },
    confidenceLevel: {
        type: DataTypes.TEXT,
        field: 'confidence_level'
    },
    embedding: {
        type: DataTypes.STRING,
        field: 'embedding'
    },
    createdAt: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW,
        field: 'created_at'
    }
}, {
    tableName: 'pepperknowledge',
    timestamps: false
});

export default PepperKnowledge;
