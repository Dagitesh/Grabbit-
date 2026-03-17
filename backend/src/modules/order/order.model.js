const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const Order = sequelize.define(
  'Order',
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    user_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: { model: 'users', key: 'id' },
      onDelete: 'RESTRICT',
    },
    deal_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: { model: 'deals', key: 'id' },
      onDelete: 'RESTRICT',
    },
    quantity: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 1,
    },
    status: {
      type: DataTypes.STRING(20),
      allowNull: false,
      defaultValue: 'Created',
    },
    claim_code: {
      type: DataTypes.STRING(64),
      allowNull: true,
      unique: true,
    },
    pickup_at: {
      type: DataTypes.DATE,
      allowNull: true,
    },
  },
  {
    tableName: 'orders',
    underscored: true,
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
  }
);

module.exports = Order;
