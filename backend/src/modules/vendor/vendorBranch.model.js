const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const VendorBranch = sequelize.define(
  'VendorBranch',
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    vendor_profile_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: { model: 'vendor_profiles', key: 'id' },
      onDelete: 'CASCADE',
    },
    subcity_id: {
      type: DataTypes.UUID,
      allowNull: true,
      references: { model: 'subcities', key: 'id' },
      onDelete: 'SET NULL',
    },
    address_detail: {
      type: DataTypes.STRING(500),
      allowNull: true,
    },
    sort_order: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
  },
  {
    tableName: 'vendor_branches',
    underscored: true,
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
  }
);

module.exports = VendorBranch;
