import { DataTypes } from 'sequelize';
import sequelize from '../config/db.js';

const District = sequelize.define('District', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
        field: 'id'
    },
    name: {
        type: DataTypes.STRING(100),
        allowNull: false,
        unique: true,
        field: 'name'
    }
}, {
    tableName: 'districts',
    timestamps: false
});

export default District;
