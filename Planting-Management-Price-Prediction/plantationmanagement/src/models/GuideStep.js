import { DataTypes } from 'sequelize';
import sequelize from '../config/db.js';

const GuideStep = sequelize.define('GuideStep', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
        field: 'id'
    },
    guideId: {
        type: DataTypes.INTEGER,
        allowNull: true,
        field: 'guideid'
    },
    stepNumber: {
        type: DataTypes.INTEGER,
        allowNull: false,
        field: 'stepnumber'
    },
    title: {
        type: DataTypes.STRING(255),
        allowNull: true,
        field: 'title'
    },
    details: {
        type: DataTypes.TEXT,
        allowNull: true,
        field: 'details'
    }
}, {
    tableName: 'guidesteps',
    timestamps: false
});

export default GuideStep;
