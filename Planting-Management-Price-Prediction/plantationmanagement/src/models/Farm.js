import { DataTypes } from 'sequelize';
import sequelize from '../config/db.js';

const Farm = sequelize.define('Farm', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        field: 'id'
    },
    userId: {
        type: DataTypes.UUID,
        allowNull: false,
        field: 'userid'
    },
    farmName: {
        type: DataTypes.STRING(255),
        allowNull: false,
        field: 'farmname'
    },
    districtId: {
        type: DataTypes.INTEGER,
        allowNull: true,
        field: 'districtid'
    },
    soilTypeId: {
        type: DataTypes.INTEGER,
        allowNull: true,
        field: 'soiltypeid'
    },
    chosenVarietyId: {
        type: DataTypes.STRING(50),
        allowNull: true,
        field: 'chosenvarietyid'
    },
    farmStartDate: {
        type: DataTypes.DATE,
        allowNull: true,
        field: 'farmstartdate'
    },
    areaHectares: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: true,
        field: 'areahectares'
    },
    totalVines: {
        type: DataTypes.INTEGER,
        allowNull: true,
        field: 'totalvines'
    },
    createdAt: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW,
        field: 'createdat'
    }
}, {
    tableName: 'farms',
    timestamps: false
});

export default Farm;
