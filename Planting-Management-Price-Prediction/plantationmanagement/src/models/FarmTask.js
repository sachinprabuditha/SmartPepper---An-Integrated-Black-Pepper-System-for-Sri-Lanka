import { DataTypes } from 'sequelize';
import sequelize from '../config/db.js';

const FarmTask = sequelize.define('FarmTask', {
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
    taskType: {
        type: DataTypes.STRING(50),
        allowNull: true,
        field: 'tasktype'
    },
    varietyKey: {
        type: DataTypes.STRING(50),
        allowNull: true,
        field: 'varietykey'
    },
    dueDate: {
        type: DataTypes.DATE,
        allowNull: true,
        field: 'duedate'
    },
    status: {
        type: DataTypes.STRING(20),
        allowNull: true,
        field: 'status'
    },
    dateCompleted: {
        type: DataTypes.DATE,
        allowNull: true,
        field: 'datecompleted'
    },
    inputDetails: {
        type: DataTypes.JSONB,
        allowNull: true,
        field: 'inputdetails'
    },
    detailedSteps: {
        type: DataTypes.JSONB,
        allowNull: true,
        field: 'detailedsteps'
    },
    reasonWhy: {
        type: DataTypes.TEXT,
        allowNull: true,
        field: 'reasonwhy'
    },
    isManual: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
        field: 'ismanual'
    },
    priority: {
        type: DataTypes.STRING(20),
        allowNull: true,
        field: 'priority'
    },
    createdAt: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW,
        field: 'createdat'
    }
}, {
    tableName: 'farmtasks',
    timestamps: false
});

export default FarmTask;
