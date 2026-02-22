import { DataTypes } from 'sequelize';
import sequelize from '../config/db.js';

const EmergencyTemplate = sequelize.define('EmergencyTemplate', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        field: 'id'
    },
    issueName: {
        type: DataTypes.STRING(255),
        allowNull: true,
        field: 'issuename'
    },
    symptoms: {
        type: DataTypes.TEXT,
        allowNull: true,
        field: 'symptoms'
    },
    treatmentTask: {
        type: DataTypes.STRING(255),
        allowNull: true,
        field: 'treatmenttask'
    },
    priority: {
        type: DataTypes.STRING(20),
        allowNull: true,
        field: 'priority'
    },
    instructions: {
        type: DataTypes.TEXT,
        allowNull: true,
        field: 'instructions'
    }
}, {
    tableName: 'emergencytemplates',
    timestamps: false
});

export default EmergencyTemplate;
