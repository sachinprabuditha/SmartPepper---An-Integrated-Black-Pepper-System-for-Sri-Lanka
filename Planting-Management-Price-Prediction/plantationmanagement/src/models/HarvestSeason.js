import { DataTypes } from 'sequelize';
import sequelize from '../config/db.js';

const HarvestSeason = sequelize.define('HarvestSeason', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        field: 'id'
    },
    farmId: {
        type: DataTypes.UUID,
        allowNull: true,
        field: 'farmid'
    },
    seasonName: {
        type: DataTypes.STRING(100),
        allowNull: true,
        field: 'seasonname'
    },
    startMonth: {
        type: DataTypes.INTEGER,
        allowNull: true,
        field: 'startmonth'
    },
    startYear: {
        type: DataTypes.INTEGER,
        allowNull: true,
        field: 'startyear'
    },
    endMonth: {
        type: DataTypes.INTEGER,
        allowNull: true,
        field: 'endmonth'
    },
    endYear: {
        type: DataTypes.INTEGER,
        allowNull: true,
        field: 'endyear'
    },
    status: {
        type: DataTypes.STRING(50),
        allowNull: true,
        field: 'status'
    },
    createdBy: {
        type: DataTypes.UUID,
        allowNull: true,
        field: 'createdby'
    }
}, {
    tableName: 'harvestseasons',
    timestamps: false
});

export default HarvestSeason;
