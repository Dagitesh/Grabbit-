const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const CustomerProfile = sequelize.define(
  'CustomerProfile',
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    user_id: {
      type: DataTypes.UUID,
      allowNull: false,
      unique: true,
      references: { model: 'users', key: 'id' },
      onDelete: 'RESTRICT',
    },
  },
  {
    tableName: 'customer_profiles',
    underscored: true,
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
  }
);

module.exports = CustomerProfile;
