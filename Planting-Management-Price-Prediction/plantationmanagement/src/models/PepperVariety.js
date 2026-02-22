import { DataTypes } from 'sequelize';
import sequelize from '../config/db.js';

const PepperVariety = sequelize.define('PepperVariety', {
    id: {
        type: DataTypes.STRING(50),
        primaryKey: true,
        field: 'id'
    },
    name: {
        type: DataTypes.STRING(100),
        allowNull: false,
        field: 'name'
    },
    specialities: {
        type: DataTypes.TEXT,
        allowNull: true,
        field: 'specialities'
    },
    suitabilityReason: {
        type: DataTypes.TEXT,
        allowNull: true,
        field: 'suitabilityreason'
    },
    soilTypeRecommendation: {
        type: DataTypes.TEXT,
        allowNull: true,
        field: 'soiltyperecommendation'
    },
    spacingMeters: {
        type: DataTypes.STRING(50),
        allowNull: true,
        field: 'spacingmeters'
    },
    vinesPerHectare: {
        type: DataTypes.INTEGER,
        allowNull: true,
        field: 'vinesperhectare'
    },
    pitDimensionsCm: {
        type: DataTypes.STRING(50),
        allowNull: true,
        field: 'pitdimensionscm'
    }
}, {
    tableName: 'peppervarieties',
    timestamps: false
});

export default PepperVariety;
