import { DataTypes } from 'sequelize';
import sequelize from '../config/db.js';

const DistrictSoil = sequelize.define('DistrictSoil', {
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
    }
}, {
    tableName: 'districtsoils',
    timestamps: false
});

export default DistrictSoil;
