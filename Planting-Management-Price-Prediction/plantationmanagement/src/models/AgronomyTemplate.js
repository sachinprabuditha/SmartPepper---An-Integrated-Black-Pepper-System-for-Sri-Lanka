import { DataTypes } from 'sequelize';
import sequelize from '../config/db.js';

const AgronomyTemplate = sequelize.define('AgronomyTemplate', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        field: 'id'
    },
    taskName: {
        type: DataTypes.STRING(255),
        allowNull: false,
        field: 'taskname'
    },
    phase: {
        type: DataTypes.STRING(50),
        allowNull: true,
        field: 'phase'
    },
    timingDaysAfterStarting: {
        type: DataTypes.INTEGER,
        allowNull: true,
        field: 'timingdaysafterstarting'
    },
    instructionalDetails: {
        type: DataTypes.TEXT,
        allowNull: true,
        field: 'instructionaldetails'
    },
    taskType: {
        type: DataTypes.STRING(50),
        allowNull: true,
        field: 'tasktype'
    },
    varietyKey: {
        type: DataTypes.STRING(50),
        allowNull: true,
        field: 'varietykey'
    }
}, {
    tableName: 'agronomytemplates',
    timestamps: false
});

export default AgronomyTemplate;
