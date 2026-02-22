import { DataTypes } from 'sequelize';
import sequelize from '../config/db.js';

const SoilType = sequelize.define('SoilType', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
        field: 'id'
    },
    typeName: {
        type: DataTypes.STRING(100),
        allowNull: false,
        unique: true,
        field: 'typename'
    }
}, {
    tableName: 'soiltypes',
    timestamps: false
});

export default SoilType;
