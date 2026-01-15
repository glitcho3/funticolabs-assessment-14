var mongoose = require('mongoose');
var propertyTypesSchema = mongoose.Schema;

propertyTypesSchema = new propertyTypesSchema({
  title: {
    type: String
  },
  type: {
    type: String,
    required: true,
    enum: ['residential', 'commercial', 'agricultural']
  },
  is_active: {
    type: Boolean,
    default: true
  },
  updatedOn: {
    type: Date,
    default: Date.now()
  },
  createdOn: {
    type: Date
  }
});

module.exports = mongoose.model('propertyTypes', propertyTypesSchema);
