import { DataTypes } from 'sequelize';
import sequelize from '../config/db.js';

const User = sequelize.define('User', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        field: 'id'
    },
    email: {
        type: DataTypes.STRING(255),
        allowNull: false,
        unique: true,
        validate: {
            isEmail: true
        },
        field: 'email'
    },
    passwordHash: {
        type: DataTypes.TEXT,
        allowNull: false,
        field: 'passwordhash'
    },
    fullName: {
        type: DataTypes.STRING(255),
        allowNull: false,
        field: 'fullname'
    },
    phoneNumber: {
        type: DataTypes.STRING(20),
        allowNull: true,
        field: 'phonenumber'
    },
    createdAt: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW,
        field: 'createdat'
    },
    updatedAt: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW,
        field: 'updatedat'
    }
}, {
    tableName: 'users',
    timestamps: false
});

export default User;
