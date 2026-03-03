const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');
const { ROLES } = require('../../config/constants');

const User = sequelize.define(
  'User',
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    full_name: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
    email: {
      type: DataTypes.STRING(255),
      allowNull: false,
      unique: true,
      validate: { isEmail: true },
    },
    phone: {
      type: DataTypes.STRING(50),
      allowNull: true,
    },
    password: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
    role: {
      type: DataTypes.STRING(20),
      allowNull: false,
      defaultValue: ROLES.CUSTOMER,
      validate: { isIn: [Object.values(ROLES)] },
    },
    is_verified: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    otp_code: {
      type: DataTypes.STRING(10),
      allowNull: true,
    },
    otp_expires_at: {
      type: DataTypes.DATE,
      allowNull: true,
    },
  },
  {
    tableName: 'users',
    underscored: true,
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    defaultScope: {
      attributes: { exclude: ['password', 'otp_code', 'otp_expires_at'] },
    },
    scopes: {
      withPassword: {
        attributes: { include: ['password', 'otp_code', 'otp_expires_at'] },
      },
      withOtp: {
        attributes: { include: ['otp_code', 'otp_expires_at'] },
      },
    },
  }
);

module.exports = User;
