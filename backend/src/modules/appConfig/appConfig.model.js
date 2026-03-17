const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const AppConfig = sequelize.define(
  'AppConfig',
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    intro_image_url: {
      type: DataTypes.STRING(500),
      allowNull: true,
    },
  },
  {
    tableName: 'app_config',
    underscored: true,
    timestamps: true,
    createdAt: false,
    updatedAt: 'updated_at',
  }
);

module.exports = AppConfig;
