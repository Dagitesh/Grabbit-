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
      // unique: true — enable after cleaning duplicate phones (see migrations/001_grabbit_schema_v2.sql)
    },
    password_hash: {
      type: DataTypes.STRING(255),
      allowNull: false,
<<<<<<< HEAD
      // Column name in DB is `password_hash` (see migrations/001_grabbit_schema_v2.sql renames legacy `password`).
=======
      field: 'password', // DB column remains "password" until you run migrations/001_grabbit_schema_v2.sql
>>>>>>> b4445c22d74b08dfbe6b25d0ba95eee6eaf515aa
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
      attributes: { exclude: ['password_hash', 'otp_code', 'otp_expires_at'] },
    },
    scopes: {
      withPassword: {
        attributes: { include: ['password_hash', 'otp_code', 'otp_expires_at'] },
      },
      withOtp: {
        attributes: { include: ['otp_code', 'otp_expires_at'] },
      },
    },
  }
);

module.exports = User;
