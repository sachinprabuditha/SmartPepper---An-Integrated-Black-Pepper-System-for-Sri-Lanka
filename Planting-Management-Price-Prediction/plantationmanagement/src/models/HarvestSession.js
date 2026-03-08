import { DataTypes } from 'sequelize';
import sequelize from '../config/db.js';

const HarvestSession = sequelize.define('HarvestSession', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        field: 'id'
    },
    seasonId: {
        type: DataTypes.UUID,
        allowNull: true,
        field: 'seasonid'
    },
    sessionName: {
        type: DataTypes.STRING(255),
        allowNull: true,
        field: 'sessionname'
    },
    date: {
        type: DataTypes.DATE,
        allowNull: true,
        field: 'date'
    },
    yieldKg: {
        type: DataTypes.DECIMAL,
        allowNull: true,
        field: 'yieldkg'
    },
    areaHarvested: {
        type: DataTypes.DECIMAL,
        allowNull: true,
        field: 'areaharvested'
    },
    notes: {
        type: DataTypes.TEXT,
        allowNull: true,
        field: 'notes'
    }
}, {
    tableName: 'harvestsessions',
    timestamps: false
});

export default HarvestSession;
