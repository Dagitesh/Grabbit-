const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const VendorProfile = sequelize.define(
  'VendorProfile',
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
      onDelete: 'CASCADE',
    },
    tin: {
      type: DataTypes.STRING(50),
      allowNull: true,
      unique: true,
    },
    business_name: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
    business_description: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    phone: {
      type: DataTypes.STRING(50),
      allowNull: false,
    },
    location: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    owner_name: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    business_type: {
      type: DataTypes.STRING(100),
      allowNull: true,
    },
    certificate_pdf_url: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    address: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    branch_count: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 1,
    },
  },
  {
    tableName: 'vendor_profiles',
    underscored: true,
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
  }
);

module.exports = VendorProfile;
