import { DataTypes } from 'sequelize';
import sequelize from '../config/db.js';

const AgronomyGuide = sequelize.define('AgronomyGuide', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
        field: 'id'
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
    varietyId: {
        type: DataTypes.STRING(50),
        allowNull: true,
        field: 'varietyid'
    }
}, {
    tableName: 'agronomyguides',
    timestamps: false
});

export default AgronomyGuide;
