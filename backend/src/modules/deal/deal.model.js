const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const Deal = sequelize.define(
  'Deal',
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    vendor_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: { model: 'users', key: 'id' },
      onDelete: 'CASCADE',
    },
    title: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    location: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    category: {
      type: DataTypes.STRING(100),
      allowNull: true,
    },
    original_price: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
    },
    discounted_price: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
    },
    quantity_available: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    expiry_date: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
    },
    images: {
      type: DataTypes.TEXT,
      allowNull: true,
      comment: 'JSON array of image URLs',
    },
  },
  {
    tableName: 'deals',
    underscored: true,
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
  }
);

module.exports = Deal;
